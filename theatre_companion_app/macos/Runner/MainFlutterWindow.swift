import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let appBg = NSColor(calibratedRed: 10/255, green: 10/255, blue: 10/255, alpha: 1)
    self.backgroundColor = appBg
    self.isOpaque = true

    // Stretch Flutter's view to fill the window on every resize / fullscreen.
    if let flutterView = flutterViewController.view {
      flutterView.autoresizingMask = [.width, .height]
      flutterView.wantsLayer = true
      flutterView.layer?.backgroundColor = appBg.cgColor
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()

    // Re-render after fullscreen transitions finish so the grey flash disappears.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onFullscreenTransitionEnd(_:)),
      name: NSWindow.didEnterFullScreenNotification,
      object: self
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onFullscreenTransitionEnd(_:)),
      name: NSWindow.didExitFullScreenNotification,
      object: self
    )
  }

  @objc private func onFullscreenTransitionEnd(_ note: Notification) {
    guard let vc = contentViewController as? FlutterViewController else { return }
    vc.view.frame = contentView?.bounds ?? vc.view.frame
    vc.view.needsDisplay = true
    vc.view.display()
  }
}
