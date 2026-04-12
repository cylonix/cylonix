import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private weak var mainFlutterViewController: FlutterViewController?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    mainFlutterViewController = flutterViewController
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.initialFirstResponder = flutterViewController.view

    RegisterGeneratedPlugins(registry: flutterViewController)

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
