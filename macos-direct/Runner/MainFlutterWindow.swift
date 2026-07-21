// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import AVFoundation
import Cocoa
import FlutterMacOS
import Security
import UserNotifications

class MainFlutterWindow: NSWindow {
  private var mediaChannel: FlutterMethodChannel?
  private var notificationsChannel: FlutterMethodChannel?
  private var directChannel: FlutterMethodChannel?
  private var notificationDelegate: ForegroundNotificationDelegate?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerMediaChannel(controller: flutterViewController)
    registerNotificationsChannel(controller: flutterViewController)
    registerDirectChannel(controller: flutterViewController)
    requestNotificationAuthorization()

    super.awakeFromNib()

    // Adjust window controls after window is ready
    //DispatchQueue.main.async { [weak self] in
    //  self?.adjustWindowControls()
    //}
  }

  private func registerMediaChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "io.cylonix.sase/media",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "generateVideoThumbnail":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let outputDir = args["outputDir"] as? String
        else {
          result(FlutterError(
            code: "bad_args",
            message: "Missing path or outputDir",
            details: nil
          ))
          return
        }
        let maxWidth = (args["maxWidth"] as? NSNumber)?.doubleValue ?? 480.0
        let quality = (args["quality"] as? NSNumber)?.intValue ?? 70
        let timeMs = (args["timeMs"] as? NSNumber)?.doubleValue ?? 0
        DispatchQueue.global(qos: .userInitiated).async {
          let outPath = MainFlutterWindow.generateVideoThumbnail(
            path: path,
            outputDir: outputDir,
            maxWidth: CGFloat(maxWidth),
            quality: quality,
            timeMs: timeMs
          )
          DispatchQueue.main.async {
            result(outPath)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    mediaChannel = channel
  }

  static func generateVideoThumbnail(
    path: String,
    outputDir: String,
    maxWidth: CGFloat,
    quality: Int,
    timeMs: Double
  ) -> String? {
    guard FileManager.default.fileExists(atPath: path) else {
      NSLog("generateVideoThumbnail: source missing at \(path)")
      return nil
    }
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    // Allow any frame near the requested time. Without this, copyCGImage will
    // throw when the requested time isn't an exact decode point — common for
    // recordings that lack a sync sample at t=0.
    generator.requestedTimeToleranceBefore = .positiveInfinity
    generator.requestedTimeToleranceAfter = .positiveInfinity
    if maxWidth > 0 {
      generator.maximumSize = CGSize(width: maxWidth, height: maxWidth * 2)
    }
    let time = CMTime(seconds: max(0, timeMs / 1000.0), preferredTimescale: 600)
    do {
      let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
      let bitmap = NSBitmapImageRep(cgImage: cgImage)
      let factor = max(0.1, min(1.0, Double(quality) / 100.0))
      guard let data = bitmap.representation(
        using: .jpeg,
        properties: [.compressionFactor: NSNumber(value: factor)]
      ) else {
        NSLog("generateVideoThumbnail: jpeg encode failed for \(path)")
        return nil
      }
      try FileManager.default.createDirectory(
        atPath: outputDir,
        withIntermediateDirectories: true
      )
      let filename = "\(UUID().uuidString).jpg"
      let outPath = (outputDir as NSString).appendingPathComponent(filename)
      try data.write(to: URL(fileURLWithPath: outPath))
      return outPath
    } catch {
      NSLog("generateVideoThumbnail failed for \(path): \(error)")
      return nil
    }
  }

  private func registerNotificationsChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "io.cylonix.sase/notifications",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "no_self", message: "channel host gone", details: nil))
        return
      }
      switch call.method {
      case "showFileReceived":
        let args = call.arguments as? [String: Any] ?? [:]
        let name = args["name"] as? String ?? ""
        let path = args["path"] as? String ?? ""
        self.showFileReceivedNotification(name: name, path: path)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    notificationsChannel = channel
  }

  private func registerDirectChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "io.cylonix.sase/direct",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "uninstallDirect":
        // Stop/remove the daemon, notifier, CLI and receipt AND delete the app
        // bundle behind a SINGLE authorization prompt. The script runs with
        // `--no-kill`, so the app stays alive to return the status report;
        // Dart shows it, then calls "quitApp".
        let args = call.arguments as? [String: Any] ?? [:]
        let purgeState = (args["purgeState"] as? NSNumber)?.boolValue ?? false
        MainFlutterWindow.runPrivilegedUninstall(purgeState: purgeState, result: result)
      case "quitApp":
        // Terminate after the uninstall report is dismissed. NSApp.terminate
        // routes through Flutter's cancelable exit request, so hard-exit as a
        // fallback — there is nothing left to clean up.
        result(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          NSApp.terminate(nil)
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { exit(0) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    directChannel = channel
  }

  /// Runs the bundled uninstall_direct.sh as root behind a SINGLE, descriptive
  /// authorization prompt, using AuthorizationExecuteWithPrivileges.
  ///
  /// The script is staged to a temp path so deleting the app bundle does not
  /// remove the file being executed, and it runs in mode `all --no-kill`:
  /// the daemon, notifier, CLI, receipt and the app bundle are all removed,
  /// but the running app is left alive so Dart can present the status report
  /// before quitting via "quitApp".
  ///
  /// The custom prompt is attached to the `kAuthorizationRightExecute` right
  /// via `kAuthorizationEnvironmentPrompt` and pre-authorized, so the system
  /// password dialog explains what is being removed. AuthorizationExecute-
  /// WithPrivileges is deprecated and not exported to Swift, so it is resolved
  /// dynamically with dlsym; this API requires the app not be sandboxed (the
  /// direct build is not). Returns the script's stdout on success, or the
  /// `cancelled` error code when the prompt is dismissed.
  static func runPrivilegedUninstall(purgeState: Bool, result: @escaping FlutterResult) {
    guard let bundled = Bundle.main.path(forResource: "uninstall_direct", ofType: "sh") else {
      result(FlutterError(
        code: "missing_script",
        message: "uninstall_direct.sh not found in app bundle",
        details: nil))
      return
    }

    let tmpPath = NSTemporaryDirectory() + "cylonix-uninstall-\(UUID().uuidString).sh"
    do {
      try? FileManager.default.removeItem(atPath: tmpPath)
      try FileManager.default.copyItem(atPath: bundled, toPath: tmpPath)
    } catch {
      result(FlutterError(
        code: "copy_failed",
        message: "Failed to stage uninstaller: \(error)",
        details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      func finish(_ value: Any?) { DispatchQueue.main.async { result(value) } }

      var authRef: AuthorizationRef?
      let createStatus = AuthorizationCreate(nil, nil, [], &authRef)
      guard createStatus == errAuthorizationSuccess, let auth = authRef else {
        finish(FlutterError(
          code: "auth_failed",
          message: "AuthorizationCreate failed (\(createStatus))",
          details: nil))
        return
      }
      defer { AuthorizationFree(auth, [.destroyRights]) }

      // Pre-authorize the execute right with a descriptive prompt so the
      // single system password dialog explains what Cylonix will remove.
      let prompt = "Cylonix needs administrator access to finish uninstalling. "
        + "This stops and removes its background service (cylonixd), the "
        + "command-line tool, and the notifier, and deletes the Cylonix app."
      let promptName = strdup(kAuthorizationEnvironmentPrompt)
      let promptValue = strdup(prompt)
      let rightName = strdup(kAuthorizationRightExecute)
      defer { free(promptName); free(promptValue); free(rightName) }

      var promptItem = AuthorizationItem(
        name: UnsafePointer(promptName!),
        valueLength: strlen(promptValue!),
        value: UnsafeMutableRawPointer(promptValue!),
        flags: 0)
      var rightItem = AuthorizationItem(
        name: UnsafePointer(rightName!),
        valueLength: 0, value: nil, flags: 0)

      let copyStatus: OSStatus = withUnsafeMutablePointer(to: &promptItem) { promptPtr in
        withUnsafeMutablePointer(to: &rightItem) { rightPtr in
          var environment = AuthorizationEnvironment(count: 1, items: promptPtr)
          var rights = AuthorizationRights(count: 1, items: rightPtr)
          let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
          return AuthorizationCopyRights(auth, &rights, &environment, flags, nil)
        }
      }
      if copyStatus == errAuthorizationCanceled {
        finish(FlutterError(code: "cancelled", message: "User cancelled", details: nil))
        return
      }
      guard copyStatus == errAuthorizationSuccess else {
        finish(FlutterError(
          code: "auth_failed",
          message: "Authorization denied (\(copyStatus))",
          details: nil))
        return
      }

      // AuthorizationExecuteWithPrivileges is deprecated and not surfaced to
      // Swift; resolve it dynamically (RTLD_DEFAULT == (void *) -2).
      typealias AEWPFn = @convention(c) (
        AuthorizationRef,
        UnsafePointer<CChar>,
        AuthorizationFlags,
        UnsafePointer<UnsafeMutablePointer<CChar>?>,
        UnsafeMutablePointer<UnsafeMutablePointer<FILE>?>?
      ) -> OSStatus
      guard let sym = dlsym(
        UnsafeMutableRawPointer(bitPattern: -2), "AuthorizationExecuteWithPrivileges")
      else {
        finish(FlutterError(
          code: "exec_unavailable",
          message: "AuthorizationExecuteWithPrivileges unavailable",
          details: nil))
        return
      }
      let execFn = unsafeBitCast(sym, to: AEWPFn.self)

      var scriptArgs = [tmpPath, "all", "--no-kill"]
      if purgeState { scriptArgs.append("--purge-state") }
      var cArgs: [UnsafeMutablePointer<CChar>?] = scriptArgs.map { strdup($0) }
      cArgs.append(nil)
      defer { for a in cArgs where a != nil { free(a) } }

      var pipe: UnsafeMutablePointer<FILE>?
      let execStatus = "/bin/zsh".withCString { toolPtr in
        cArgs.withUnsafeBufferPointer { argsBuf in
          execFn(auth, toolPtr, [], argsBuf.baseAddress!, &pipe)
        }
      }
      guard execStatus == errAuthorizationSuccess else {
        if execStatus == errAuthorizationCanceled {
          finish(FlutterError(code: "cancelled", message: "User cancelled", details: nil))
        } else {
          finish(FlutterError(
            code: "uninstall_failed",
            message: "Privileged execution failed (\(execStatus))",
            details: nil))
        }
        return
      }

      var output = ""
      if let pipe = pipe {
        let handle = FileHandle(fileDescriptor: fileno(pipe), closeOnDealloc: false)
        let data = handle.readDataToEndOfFile()
        output = String(data: data, encoding: .utf8)?
          .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        fclose(pipe)
      }
      finish(output)
    }
  }

  private func requestNotificationAuthorization() {
    let center = UNUserNotificationCenter.current()
    let delegate = ForegroundNotificationDelegate()
    center.delegate = delegate
    notificationDelegate = delegate
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        NSLog("UNUserNotification requestAuthorization error: \(error)")
      }
      NSLog("UNUserNotification authorization granted=\(granted)")
    }
  }

  private func showFileReceivedNotification(name: String, path: String) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized
              || settings.authorizationStatus == .provisional
              || settings.authorizationStatus == .notDetermined else {
        NSLog("Notification not authorized; skipping file-received notification")
        return
      }
      let content = UNMutableNotificationContent()
      content.title = "File Received"
      let displayName = name.isEmpty ? "a file" : name
      content.body = "Saved \(displayName) to Downloads/Cylonix"
      content.sound = .default
      if !path.isEmpty {
        content.userInfo = ["path": path]
      }
      let request = UNNotificationRequest(
        identifier: "cylonix-file-\(UUID().uuidString)",
        content: content,
        trigger: nil
      )
      center.add(request) { err in
        if let err = err {
          NSLog("Failed to schedule file-received notification: \(err)")
        }
      }
    }
  }

  private func adjustWindowControls() {
    let buttonInset = NSPoint(x: 20, y: -10)

    guard let closeButton = standardWindowButton(.closeButton),
          let minimizeButton = standardWindowButton(.miniaturizeButton),
          let zoomButton = standardWindowButton(.zoomButton)
    else {
      return
    }

    print("adjusting button locations to 20:-10")
    closeButton.setFrameOrigin(buttonInset)

    let minimizeX = buttonInset.x + 20
    minimizeButton.setFrameOrigin(NSPoint(x: minimizeX, y: buttonInset.y))

    let zoomX = minimizeX + 20
    zoomButton.setFrameOrigin(NSPoint(x: zoomX, y: buttonInset.y))
  }
}

/// Lets file-received banners appear even when Cylonix.app is focused;
/// without a delegate, macOS suppresses notifications from the active app.
final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
