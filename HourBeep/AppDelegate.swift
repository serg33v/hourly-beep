import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var intervalMinutes: Int = 60
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBarItem()
        setupHourlyTimer()
    }
    
    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            if let image = createBellIcon() {
                button.image = image
                button.image?.isTemplate = true
            } else {
                button.title = "🔔"
            }
            button.toolTip = "Hour Beep - Hourly notification"
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Beep", action: #selector(manualBeep), keyEquivalent: "b"))
        menu.addItem(NSMenuItem.separator())
        
        let interval15 = NSMenuItem(title: "15 minutes", action: #selector(setInterval15), keyEquivalent: "")
        let interval30 = NSMenuItem(title: "30 minutes", action: #selector(setInterval30), keyEquivalent: "")
        let interval60 = NSMenuItem(title: "1 hour", action: #selector(setInterval60), keyEquivalent: "")
        
        interval60.state = .on
        
        menu.addItem(interval15)
        menu.addItem(interval30)
        menu.addItem(interval60)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Hour Beep", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupHourlyTimer() {
        timer?.invalidate()
        
        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
            self.playBeep()
        }
    }
    
    
    private func playBeep() {
        if let path = Bundle.main.path(forResource: "beep", ofType: "mp3"),
           let url = URL(string: "file://" + path) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = 0.8
                audioPlayer?.play()
            } catch {
                fallbackBeep()
            }
        } else {
            fallbackBeep()
        }
    }
    
    private func fallbackBeep() {
        if let beepSound = NSSound(named: "Basso") {
            beepSound.volume = 0.8
            beepSound.play()
        } else {
            NSSound.beep()
        }
    }
    
    @objc private func manualBeep() {
        self.playBeep()
    }
    
    @objc private func setInterval15() {
        updateInterval(15)
    }
    
    @objc private func setInterval30() {
        updateInterval(30)
    }
    
    @objc private func setInterval60() {
        updateInterval(60)
    }
    
    private func updateInterval(_ minutes: Int) {
        intervalMinutes = minutes
        setupHourlyTimer()
        updateMenuCheckmarks()
    }
    
    private func updateMenuCheckmarks() {
        guard let menu = statusItem?.menu else { return }
        
        for item in menu.items {
            if item.title == "15 minutes" || item.title == "30 minutes" || item.title == "1 hour" {
                item.state = .off
                
                if (item.title == "15 minutes" && intervalMinutes == 15) ||
                   (item.title == "30 minutes" && intervalMinutes == 30) ||
                   (item.title == "1 hour" && intervalMinutes == 60) {
                    item.state = .on
                }
            }
        }
    }
    
    private func createBellIcon() -> NSImage? {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let bellPath = NSBezierPath()
        
        // Bell main body - flipped coordinates (higher y = top)
        // Top handle/mount
        bellPath.move(to: NSPoint(x: 7.5, y: 14))
        bellPath.line(to: NSPoint(x: 8.5, y: 14))
        
        // Bell body - rounded top, flared bottom
        bellPath.move(to: NSPoint(x: 4, y: 10))
        bellPath.curve(to: NSPoint(x: 8, y: 14), controlPoint1: NSPoint(x: 4, y: 12), controlPoint2: NSPoint(x: 6, y: 14))
        bellPath.curve(to: NSPoint(x: 12, y: 10), controlPoint1: NSPoint(x: 10, y: 14), controlPoint2: NSPoint(x: 12, y: 12))
        
        // Sides going down and out
        bellPath.curve(to: NSPoint(x: 13, y: 6), controlPoint1: NSPoint(x: 12, y: 8.5), controlPoint2: NSPoint(x: 12.5, y: 7))
        bellPath.curve(to: NSPoint(x: 14, y: 5), controlPoint1: NSPoint(x: 13.3, y: 5.7), controlPoint2: NSPoint(x: 13.7, y: 5.3))
        
        // Bottom opening
        bellPath.line(to: NSPoint(x: 2, y: 5))
        
        // Left side back up
        bellPath.curve(to: NSPoint(x: 3, y: 6), controlPoint1: NSPoint(x: 2.3, y: 5.3), controlPoint2: NSPoint(x: 2.7, y: 5.7))
        bellPath.curve(to: NSPoint(x: 4, y: 10), controlPoint1: NSPoint(x: 3.5, y: 7), controlPoint2: NSPoint(x: 4, y: 8.5))
        
        bellPath.close()
        
        // Fill the bell
        NSColor.black.setFill()
        bellPath.fill()
        
        // Bell clapper - small oval hanging down
        let clapperPath = NSBezierPath(ovalIn: NSRect(x: 7.5, y: 2, width: 1, height: 2))
        NSColor.black.setFill()
        clapperPath.fill()
        
        image.unlockFocus()
        
        return image
    }
    
    @objc private func quitApp() {
        timer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
