// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import AVFoundation
import Cocoa
import FlutterMacOS
import UserNotifications

class MainFlutterWindow: NSWindow {
  private var mediaChannel: FlutterMethodChannel?
  private var notificationsChannel: FlutterMethodChannel?
  private var notificationDelegate: ForegroundNotificationDelegate?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerMediaChannel(controller: flutterViewController)
    registerNotificationsChannel(controller: flutterViewController)
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
