import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Раскладка «модель слева — описание справа» рассчитана на широкое окно.
    self.minSize = NSSize(width: 960, height: 640)
    let preferred = NSSize(width: 1440, height: 900)
    if let screen = self.screen ?? NSScreen.main {
      let visible = screen.visibleFrame
      let size = NSSize(
        width: min(preferred.width, visible.width),
        height: min(preferred.height, visible.height))
      let origin = NSPoint(
        x: visible.midX - size.width / 2,
        y: visible.midY - size.height / 2)
      self.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
