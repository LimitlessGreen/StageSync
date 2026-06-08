import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Match the Flutter app's dark background so the native window never
    // shows grey — especially visible during fullscreen transitions and
    // in areas not covered by a Flutter widget.
    self.backgroundColor = NSColor(
      calibratedRed: 10.0/255.0,
      green: 10.0/255.0,
      blue: 10.0/255.0,
      alpha: 1.0
    )
    self.isOpaque = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
