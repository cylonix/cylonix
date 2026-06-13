// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import AVFoundation
import Cocoa
import FlutterMacOS
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
      case "uninstallServices":
        // Phase 1: stop/remove the daemon, notifier, CLI and receipt; return a
        // status report. Does NOT delete the app bundle or quit the app.
        let args = call.arguments as? [String: Any] ?? [:]
        let purgeState = (args["purgeState"] as? NSNumber)?.boolValue ?? false
        MainFlutterWindow.runUninstallPhase(
          mode: "services", purgeState: purgeState, result: result)
      case "deleteApp":
        // Phase 2: delete /Applications/Cylonix.app and terminate this app.
        MainFlutterWindow.runUninstallPhase(
          mode: "app", purgeState: false, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    directChannel = channel
  }

  /// Runs one phase of the bundled uninstall_direct.sh as root.
  ///
  /// The script is copied to a temp path first so the "app" phase can delete
  /// the app bundle without removing the file it is executing. It runs
  /// synchronously under security_authtrampoline (an independent privileged
  /// process tree), so the "app" phase's trailing `killall Cylonix` terminates
  /// this app only after deletion has finished. macOS caches the admin
  /// authorization for ~5 minutes, so the second phase does not re-prompt.
  ///
  /// The phase's stdout (a "• …" status report) is returned to Dart on
  /// success; a dismissed password prompt maps to the `cancelled` error code.
  static func runUninstallPhase(
    mode: String, purgeState: Bool, result: @escaping FlutterResult
  ) {
    guard let bundled = Bundle.main.path(forResource: "uninstall_direct", ofType: "sh") else {
      result(FlutterError(
        code: "missing_script",
        message: "uninstall_direct.sh not found in app bundle",
        details: nil
      ))
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
        details: nil
      ))
      return
    }

    let flag = purgeState ? " --purge-state" : ""
    let shellCmd = "/bin/zsh \(tmpPath) \(mode)\(flag)"
    // Escape for embedding inside an AppleScript double-quoted string.
    let escaped = shellCmd
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    let appleScript = "do shell script \"\(escaped)\" with administrator privileges"

    DispatchQueue.global(qos: .userInitiated).async {
      let task = Process()
      task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
      task.arguments = ["-e", appleScript]
      let stdoutPipe = Pipe()
      let stderrPipe = Pipe()
      task.standardOutput = stdoutPipe
      task.standardError = stderrPipe
      do {
        try task.run()
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "uninstall_failed",
            message: "Failed to launch osascript: \(error)",
            details: nil
          ))
        }
        return
      }
      let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
      let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
      task.waitUntilExit()
      let outStr = String(data: outData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let errStr = String(data: errData, encoding: .utf8) ?? ""
      DispatchQueue.main.async {
        if task.terminationStatus == 0 {
          // do shell script returns the command's stdout — the status report.
          result(outStr)
        } else if errStr.contains("-128")
          || errStr.localizedCaseInsensitiveContains("User canceled") {
          // User dismissed the authorization prompt.
          result(FlutterError(code: "cancelled", message: "User cancelled", details: nil))
        } else {
          result(FlutterError(
            code: "uninstall_failed",
            message: errStr.isEmpty
              ? "osascript exited \(task.terminationStatus)" : errStr,
            details: nil
          ))
        }
      }
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
