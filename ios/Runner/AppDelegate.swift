#if os(iOS)
    import Flutter
    import UIKit
#elseif os(macOS)
    import Cocoa
    import FlutterMacOS
#endif
import NetworkExtension
import UserNotifications
#if SWIFT_PACKAGE
    import WireGuardKitGo
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
    var methodChannel: FlutterMethodChannel?
    var tunnelsManager: TunnelsManager?

    let channel: String = "io.cylonix.sase/wg"
    let tunnelName: String = "Cylonix Tunnel"
    let serverAddress: String = "Cylonix Mesh"
    var inStartLogin: Bool = false

    private func getCylonixTunnelConfiguration() -> TunnelConfiguration {
        let interface = InterfaceConfiguration(privateKey: PrivateKey())
        return TunnelConfiguration(name: tunnelName, interface: interface, peers: [], serverAddress: serverAddress)
    }

    private func invokeMethod(_ method: String, arguments: Any?) {
        guard let channel = methodChannel else {
            wg_log(.error, message: "Method channel not initialized when calling '\(method)'")
            return
        }
        if !Thread.isMainThread {
            // wg_log(.debug, message: "Invoking method '\(method)' on background thread. Dispatching to main thread.")
            DispatchQueue.main.async {
                self.invokeMethod(method, arguments: arguments)
            }
            return
        }
        channel.invokeMethod(method, arguments: arguments) { r in
            if r != nil {
                // wg_log(.debug, message: "Invoke methold channel for method '\(method)' result: \(r as Optional)")
            }
        }
    }

    private func getTunnel() -> TunnelContainer? {
        return tunnelsManager!.tunnel(named: tunnelName)
    }

    private func setupOrUpdateTunnel() {
        let onDemandOption = ActivateOnDemandOption.anyInterface(ActivateOnDemandSSIDOption.anySSID)
        var tunnelConfig = getCylonixTunnelConfiguration()
        if let tunnel = getTunnel() {
            // Tunnel already exits
            wg_log(.info, message: "Tunnel '\(tunnel.name)' has been setup. Set on demand enable.")
            if let currentTunnelConfig = tunnel.tunnelConfiguration {
                if currentTunnelConfig.name == tunnelConfig.name {
                    tunnelConfig = currentTunnelConfig
                }
            }

            if tunnel.isActivateOnDemandEnabled {
                // Name matched and on-demand enabled. All set.
                let status = tunnel.status
                wg_log(.info, message: "Tunnel '\(tunnel.name)' on demand is already enabled. Current status '\(status)'.")
                invokeMethod("tunnelStatus", arguments: ["status": "\(status)"])
                if status == .inactive {
                    wg_log(.info, message: "Tunnel '\(tunnel.name)' is inactive. Start the tunnel.")
                    tunnelsManager!.start(tunnel.name)
                }
                return
            }

            // Enable tunnel on Demand option.
            tunnelsManager!.modify(tunnel: tunnel, tunnelConfiguration: tunnelConfig, onDemandOption: onDemandOption, shouldEnsureOnDemandEnabled: true) { error in
                if error != nil {
                    let msg = "Failed to enable on demand for VPN Tunnel '\(tunnel.name)': \(error!)"
                    wg_log(.error, message: msg)
                    self.invokeMethod("tunnelStatus", arguments: ["status": "invalid", "error": msg])
                    return
                }
                let status = TunnelStatus.waiting
                self.tunnelsManager!.start(tunnel.name)
                self.invokeMethod("tunnelStatus", arguments: ["status": "\(status)"])
            }
            return
        }
        tunnelsManager!.add(tunnelConfiguration: tunnelConfig, onDemandOption: onDemandOption) {
            result in
            var status = TunnelStatus.inactive
            switch result {
            case let .failure(error):
                let msg = "Failed to add VPN tunnel '\(String(describing: tunnelConfig.name))': \(error)"
                wg_log(.error, message: msg)
            case .success:
                wg_log(.debug, message: "VPN tunnel '\(String(describing: tunnelConfig.name))' added successfully")
                status = TunnelStatus.waiting
            }
            self.tunnelsManager!.start(tunnelConfig.name!)
            self.invokeMethod("tunnelStatus", arguments: ["status": "\(status)"])
        }
    }

    private func handleTunnelCreateResult(_ id: String, _ result: Result<TunnelsManager, TunnelsManagerError>) {
        switch result {
        case let .failure(error):
            let (_, message) = error.alertText
            let alertMessage = "Tunnel creation failed: \(message)"
            wg_log(.error, message: alertMessage)
            invokeMethod("tunnelStatus", arguments: ["status": "invalid", "error": alertMessage])
            invokeMethod("tunnelCreated", arguments: ["id": id, "isCreated": false])
        case let .success(tunnelsMgr):
            wg_log(.info, message: "Tunnel manager created: tunnelsMgr=\(tunnelsMgr)")
            invokeMethod("tunnelCreated", arguments: ["id": id, "isCreated": true])
            tunnelsManager = tunnelsMgr

            TunnelsManager.onTunnelStatusChange { tunnelName, status in
                wg_log(.info, message: "Tunnel '\(tunnelName)' status changed to '\(status)'.")
                if tunnelName != self.tunnelName {
                    wg_log(.debug, message: "Tunnel '\(tunnelName)' is not ours '\(self.tunnelName)', ignoring status change.")
                    if let tunnel = self.tunnelsManager?.tunnel(named: tunnelName) {
                        wg_log(.info, message: "Removing Tunnel '\(tunnelName)' since we should only have 1 tunnel.")
                        self.tunnelsManager?.remove(tunnel: tunnel) { error in
                            if error != nil {
                                wg_log(.error, message: "Failed to remove tunnel '\(tunnelName): \(String(describing: error))")
                            } else {
                                wg_log(.info, message: "Tunnel '\(tunnelName)' is removed.")
                            }
                        }
                    }
                    return
                }
                self.invokeMethod("tunnelStatus", arguments: ["status": status])
            }

            setupOrUpdateTunnel()
        }
    }

    private func setupTunnelsManager(_ id: String = "") {
        wg_log(.info, staticMessage: "creating tunnels manager")
        TunnelsManager.create { result in
            self.handleTunnelCreateResult(id, result)
        }
    }

    private func checkVPNPermission(_ id: String = "") {
        wg_log(.info, staticMessage: "check vpn permission")
        TunnelsManager.isPrepared { result in
            var state = false
            switch result {
            case let .success(isPrepared):
                wg_log(.info, message: "VPN is prepared: \(isPrepared)")
                state = isPrepared
            case let .failure(error):
                wg_log(.error, message: "Failed to check VPN preparation: \(error)")
            }
            self.invokeMethod("tunnelCreated", arguments: ["isCreated": state, "id": id])
        }
    }

    #if os(iOS)
        override func application(
            _: UIApplication,
            didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            wg_log(.info, staticMessage: "iOS app launched.")
            return commonDidFinishLaunching()
        }

        override func applicationDidBecomeActive(_ application: UIApplication) {
            super.applicationDidBecomeActive(application)
            BackgroundTaskManager.shared.processFilesFromSharedContainer { _ in }
        }

    #elseif os(macOS)
        override func applicationDidFinishLaunching(_: Notification) {
            wg_log(.info, staticMessage: "macOS app launched, starting initialization")
            _ = commonDidFinishLaunching()
            wg_log(.info, staticMessage: "macOS app initialization completed")
        }

        override func applicationWillTerminate(_: Notification) {
            wg_log(.info, staticMessage: "macOS app terminating...")
        }
    #endif

    private func commonDidFinishLaunching() -> Bool {
        Logger.configureGlobal(tagged: "APP", withFilePath: FileManager.logFileURL?.path)
        setupTunnelNotificationObserver()
        setupFilesWaitingNotificationObserver()
        setupShareNotificationObserver()
        setupUserNotifications()

        #if os(iOS)
            wg_log(.info, staticMessage: "iOS app launched. Setting up method channel")
            let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
            methodChannel = FlutterMethodChannel(
                name: "io.cylonix.sase/wg",
                binaryMessenger: controller.binaryMessenger
            )

            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().delegate = self
            }
        #elseif os(macOS)
            wg_log(.info, staticMessage: "macOS app launched. Setting up method channel")
            let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
            methodChannel = FlutterMethodChannel(
                name: "io.cylonix.sase/wg",
                binaryMessenger: controller.engine.binaryMessenger
            )
        #endif

        methodChannel!.setMethodCallHandler {
            (call: FlutterMethodCall, result: FlutterResult) in
            if call.method == "create_tunnels_manager" {
                self.setupTunnelsManager(call.arguments as? String ?? "")
                result("Success")
                return
            }
            if call.method == "checkVPNPermission" {
                self.checkVPNPermission(call.arguments as? String ?? "")
                result("Success")
                return
            }

            // All cylonixd related calls should go through packet tunnel
            // provider as it is a separate process.
            guard let tunnelsMgr = self.tunnelsManager else {
                let message = "FAILED: tunnels manager is nil. command: \(call.method)"
                wg_log(.error, message: message)
                result(message)
                return
            }

            switch call.method {
            case "getLogs":
                result(self.handleGetWgLogs(tunnelsMgr, call.arguments as? String ?? ""))
            case "getSharedFolderPath":
                let sharedFolderURL = FileManager.sharedFolderURL
                wg_log(.debug, message: "Shared folder URL: \(String(describing: sharedFolderURL?.path))")
                result(sharedFolderURL?.path)
            case "sendCommand":
                // "sendCommand" is used to send command to the tunnel
                // provider. The command is sent to the tunnel provider
                // process and the result is sent back to the flutter
                // app. Setting the 'id' to empty string means that the
                // result is not needed.
                guard let arguments = call.arguments as? [String: String]
                else {
                    let message = "Invalid arguments: \(String(describing: call.arguments))"
                    wg_log(.error, message: message)
                    result(message)
                    return
                }

                guard let cmd = arguments["cmd"], let id = arguments["id"], let args = arguments["args"] else {
                    let message = "Invalid arguments: \(arguments)"
                    wg_log(.error, message: message)
                    result(message)
                    return
                }

                tunnelsMgr.sendCommand(self.tunnelName, cmd, args) { result in
                    // wg_log(.debug, message: "sendCommand result: \(result)")
                    if id == "" {
                        // No need to send result back to flutter
                        return
                    }
                    self.invokeMethod("commandResult", arguments: ["cmd": cmd, "id": id, "result": result])

                    // Save tailchat service state if command succeeds
                    if result == "Success" && (cmd == "start_tailchat" || cmd == "stop_tailchat") {
                        if let appGroupId = FileManager.appGroupId,
                           let groupDefaults = UserDefaults(suiteName: appGroupId)
                        {
                            let state = cmd == "start_tailchat" ? "enabled" : "disabled"
                            groupDefaults.set(cmd == "start_tailchat", forKey: "tailchat_service_enabled")
                            // Post Darwin notification for state change
                            let center = CFNotificationCenterGetDarwinNotifyCenter()
                            let name = "io.cylonix.sase.tailchat.stateChange" as CFString
                            CFNotificationCenterPostNotification(
                                center,
                                CFNotificationName(name),
                                nil,
                                nil,
                                true
                            )
                            wg_log(.debug, message: "Saved tailchat service state as '\(state)' in app group defaults and notified")
                        } else {
                            wg_log(.error, message: "Failed to access app group defaults")
                        }
                    }
                }

                result("Success")
            default:
                result("Error: unknown method \(call.method)")
            }
        }
        #if os(iOS)
            GeneratedPluginRegistrant.register(with: self)
        #elseif os(macOS)
            RegisterGeneratedPlugins(registry: controller.engine)
        #endif
        return true
    }

    private func setupUserNotifications() {
        let center = UNUserNotificationCenter.current()

        // Request permission
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                wg_log(.debug, message: "Notification permission granted")
            } else {
                wg_log(.error, message: "Notification permission denied: \(String(describing: error))")
            }
        }
    }

    private func handleGetWgLogs(_ tunnelsMgr: TunnelsManager, _ id: String) -> String {
        wg_log(.debug, message: "handleGetWgLogs")
        tunnelsMgr.getWgLogs { logs in
            for log in logs { print(log) }
            wg_log(.debug, message: "wg logs retrived with \(logs.count) lines id=\(id)")
            self.invokeMethod("logs", arguments: ["id": id, "logs": logs])
        }
        return "Success"
    }

    private func setupTunnelNotificationObserver() {
        // Register for Darwin notifications
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        wg_log(.debug, message: "Registering for tunnel notifications")
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer!).takeUnretainedValue()
                appDelegate.handleTunnelNotification()
            },
            PacketTunnelNotification.ipnNotify as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func setupFilesWaitingNotificationObserver() {
        // Observe Darwin notifications
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        wg_log(.debug, message: "Registering for files waiting notifications")
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, name, _, _ in
                wg_log(.debug, message: "Received files waiting notification: \(name as Optional)")
                guard let observer = observer,
                      let name = name?.rawValue as String?,
                      name == PacketTunnelNotification.filesWaiting as String
                else {
                    wg_log(.error, message: "Invalid notification or observer: \(name as Optional)")
                    return
                }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                appDelegate.handleFilesWaitingNotification()
            },
            PacketTunnelNotification.filesWaiting as CFString,
            nil,
            .deliverImmediately
        )
        wg_log(.debug, message: "Files waiting notification observers setup complete")
    }

    private func handleFilesWaitingNotification() {
        wg_log(.debug, message: "handleFilesWaitingNotification")
        // Ensure serial processing of notifications
        notificationQueue.async {
            self._handleFilesWaitingNotification()
        }
    }

    private func _handleFilesWaitingNotification() {
        wg_log(.debug, message: "Processing files waiting notification")
        BackgroundTaskManager.shared.processFilesFromSharedContainer { success in
            if success {
                wg_log(.debug, message: "Successfully processed files from shared container")
            } else {
                wg_log(.error, message: "Failed to process files from shared container")
            }
        }
    }

    private let notificationQueue = DispatchQueue(label: "io.cylonix.sase.notificationQueue")
    private func handleTunnelNotification() {
        // Ensure serial processing of notifications
        notificationQueue.async {
            self._handleTunnelNotification()
        }
    }

    private func _handleTunnelNotification() {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        let timeout = DispatchTime.now() + .seconds(5) // 5 second timeout
        let timeoutGroup = DispatchGroup()
        timeoutGroup.enter()

        guard let sharedContainerURL = FileManager.sharedFolderURL else {
            wg_log(.error, message: "Failed to get app shared container URL for notifications")
            return
        }

        coordinator.coordinate(readingItemAt: sharedContainerURL, options: [], error: &error) { url in
            defer { timeoutGroup.leave() }

            let queueFile = url.appendingPathComponent("notification_queue.json")
            // wg_log(.debug, message: "Reading notification queue from \(queueFile.path)")

            guard let data = try? Data(contentsOf: queueFile),
                  let queue = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else {
                wg_log(.error, message: "Failed to read notification queue")
                return
            }
            // wg_log(.debug, message: "Notification queue has \(queue.count) items")

            // Track last processed timestamp
            let lastProcessedKey = "LastProcessedNotificationTimestamp"
            let lastProcessed = UserDefaults.standard.double(forKey: lastProcessedKey)

            // Process only new notifications (queue is append-only)
            var idx = -1
            for index in 0 ..< queue.count {
                let itemIndex = queue.count - 1 - index
                let item = queue[itemIndex]
                let timestamp = item["timestamp"] as? Double ?? 0
                if timestamp <= lastProcessed {
                    // We've reached already processed notifications, stop here
                    // wg_log(.debug, message: "Processing notification with timestamp: \(timestamp) \(lastProcessed)")
                    break
                }
                idx = itemIndex
                if index == 0 {
                    // wg_log(.debug, message: "Updating last processed timestamp to \(timestamp)")
                    UserDefaults.standard.set(timestamp, forKey: lastProcessedKey)
                }
            }
            // wg_log(.debug, message: "Last processed notification index: \(idx)")
            if idx >= 0 {
                for index in idx ..< queue.count {
                    let item = queue[index]
                    if let notification = item["notification"] as? String {
                        // Truncate notification for debug logging
                        // let maxLength = 256
                        // let truncated = notification.count > maxLength ?
                        //    notification.prefix(maxLength) + "..." :
                        //    notification
                        // wg_log(.debug, message: "Processing notification: \(truncated)")
                        invokeMethod("notification", arguments: notification)
                    }
                }
            }
            // wg_log(.debug, message: "DONE processing notifications from queue")
        }
        if let error = error {
            wg_log(.error, message: "Failed to read notification queue: \(error.localizedDescription)")
        }
        // Wait with timeout
        switch timeoutGroup.wait(timeout: timeout) {
        case .success:
            if let error = error {
                wg_log(.error, message: "Failed to read notification queue: \(error.localizedDescription)")
            } else {
                // wg_log(.debug, message: "Successfully read notification queue")
            }
        case .timedOut:
            wg_log(.error, message: "Timeout while reading notification queue")
            coordinator.cancel()
        }
    }

    #if os(macOS)
        override func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
            return true
        }

        override func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
            return true
        }
    #endif

    private func setupShareNotificationObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer!).takeUnretainedValue()
                appDelegate.handleShareNotification()
            },
            "io.cylonix.sase.share.received" as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func handleShareNotification() {
        guard let appGroupId = FileManager.appGroupId,
              let sharedDefaults = UserDefaults(suiteName: appGroupId)
        else {
            wg_log(.error, message: "Failed to access shared defaults")
            return
        }

        guard let jsonString = sharedDefaults.string(forKey: "SharedFiles") else {
            wg_log(.error, message: "No shared files data found in UserDefaults")
            return
        }

        // Clear the shared data immediately after reading
        sharedDefaults.removeObject(forKey: "SharedFiles")
        sharedDefaults.synchronize()

        // Send to Flutter
        wg_log(.debug, message: "Sending shared content to Flutter")
        invokeMethod("sharedContent", arguments: jsonString)
    }
}

extension AppDelegate {
    #if os(iOS)
        override func userNotificationCenter(
            _: UNUserNotificationCenter,
            willPresent _: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            // Show banner and play sound even when app is active
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound])
            } else {
                completionHandler([.alert, .sound])
            }
        }

        override func userNotificationCenter(
            _: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            if response.actionIdentifier == "OPEN_FOLDER" {
                let downloadsURL = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0].appendingPathComponent("Downloads")

                // Use Files app URL scheme
                if let filesAppURL = URL(string: "shareddocuments://\(downloadsURL.path)") {
                    UIApplication.shared.open(filesAppURL, options: [:]) { success in
                        if !success {
                            // Fallback to regular URL if Files app scheme fails
                            UIApplication.shared.open(downloadsURL)
                        }
                    }
                }
            }
            completionHandler()
        }

        override func application(_: UIApplication,
                                  continue userActivity: NSUserActivity,
                                  restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
        {
            // Only handle universal links
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
               let url = userActivity.webpageURL
            {
                handleAppLink(url)
                return true
            }
            return false
        }

    #elseif os(macOS)
        func userNotificationCenter(
            _: UNUserNotificationCenter,
            willPresent _: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            // Show banner and play sound even when app is active
            if #available(macOS 11.0, *) {
                completionHandler([.banner, .sound])
            } else {
                completionHandler([.alert, .sound])
            }
        }

        func userNotificationCenter(
            _: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            if response.actionIdentifier == "OPEN_FOLDER" {
                let downloadsURL = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                NSWorkspace.shared.open(downloadsURL)
            }
            completionHandler()
        }

        override func application(_: NSApplication,
                                  open urls: [URL])
        {
            // Handle app links
            if let url = urls.first {
                handleAppLink(url)
            }
        }
    #endif

    private func handleAppLink(_ url: URL) {
        wg_log(.debug, message: "Handling app link: \(url)")

        // Example: cylonix://connect?peer=xyz&action=share
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            wg_log(.error, message: "Invalid URL format")
            return
        }

        // Convert URL parameters to a map for Flutter
        var params: [String: String] = [:]
        components.queryItems?.forEach { item in
            if let value = item.value {
                params[item.name] = value
            }
        }

        // Send to Flutter via method channel
        invokeMethod("handleAppLink", arguments: [
            "path": components.path,
            "params": params,
        ])
    }
}
