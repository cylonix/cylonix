import AVFoundation
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private weak var mainFlutterViewController: FlutterViewController?
  private var mediaChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    mainFlutterViewController = flutterViewController
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.initialFirstResponder = flutterViewController.view

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerMediaChannel(controller: flutterViewController)

    super.awakeFromNib()
    restoreFlutterFirstResponder()

    // Adjust window controls after window is ready
    //DispatchQueue.main.async { [weak self] in
    //  self?.adjustWindowControls()
    //}
  }

  override func becomeKey() {
    super.becomeKey()
    restoreFlutterFirstResponder()
  }

  override func makeKeyAndOrderFront(_ sender: Any?) {
    super.makeKeyAndOrderFront(sender)
    restoreFlutterFirstResponder()
  }

  private func restoreFlutterFirstResponder() {
    guard let flutterView = mainFlutterViewController?.view else {
      return
    }

    // Flutter desktop expects its root NSView to own first-responder status
    // so text input can attach correctly after activation changes.
    if firstResponder !== flutterView {
      makeFirstResponder(flutterView)
    }
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
    // AVAssetImageGenerator default tolerances are zero, so it must find an
    // exact frame at the requested time. For some encoders (especially camera
    // captures) frame zero may not be an instantaneous decode point, which
    // makes copyCGImage throw. Allow any frame near the requested time.
    generator.requestedTimeToleranceBefore = .positiveInfinity
    generator.requestedTimeToleranceAfter = .positiveInfinity
    if maxWidth > 0 {
      // Pick a generous height bound; AVAssetImageGenerator preserves aspect.
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
