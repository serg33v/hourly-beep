import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var intervalTimer: Timer?
    private var alarmTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var intervalMinutes: Int = 60
    private var alarmMinutes: Int = 0
    private var isTimerEnabled: Bool = false
    private var isAlarmEnabled: Bool = true
    
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
        
        menu.addItem(NSMenuItem(title: "Beep", action: #selector(manualBeep), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Timer section header
        let timerHeader = NSMenuItem(title: "Timer", action: nil, keyEquivalent: "")
        timerHeader.isEnabled = false
        menu.addItem(timerHeader)
        
        let timer15 = NSMenuItem(title: "  Every 15 minutes", action: #selector(setTimer15), keyEquivalent: "")
        let timer30 = NSMenuItem(title: "  Every 30 minutes", action: #selector(setTimer30), keyEquivalent: "")
        let timer60 = NSMenuItem(title: "  Every 1 hour", action: #selector(setTimer60), keyEquivalent: "")
        
        menu.addItem(timer15)
        menu.addItem(timer30)
        menu.addItem(timer60)
        
        menu.addItem(NSMenuItem.separator())
        
        // Alarm section header
        let alarmHeader = NSMenuItem(title: "Alarm", action: nil, keyEquivalent: "")
        alarmHeader.isEnabled = false
        menu.addItem(alarmHeader)
        
        let alarm15 = NSMenuItem(title: "  At X:15", action: #selector(setAlarm15), keyEquivalent: "")
        let alarm30 = NSMenuItem(title: "  At X:30", action: #selector(setAlarm30), keyEquivalent: "")
        let alarm45 = NSMenuItem(title: "  At X:45", action: #selector(setAlarm45), keyEquivalent: "")
        let alarm00 = NSMenuItem(title: "  At X:00", action: #selector(setAlarm00), keyEquivalent: "")
        
        alarm00.state = .on
        
        menu.addItem(alarm15)
        menu.addItem(alarm30)
        menu.addItem(alarm45)
        menu.addItem(alarm00)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Hour Beep", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupHourlyTimer() {
        setupIntervalTimer()
        setupAlarmTimer()
    }
    
    private func setupIntervalTimer() {
        intervalTimer?.invalidate()
        
        if isTimerEnabled {
            let intervalSeconds = TimeInterval(intervalMinutes * 60)
            intervalTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
                self.playBeep()
            }
        }
    }
    
    private func setupAlarmTimer() {
        alarmTimer?.invalidate()
        
        if isAlarmEnabled {
            let calendar = Calendar.current
            let now = Date()
            
            var nextAlarmTime: Date?
            
            if alarmMinutes == 0 {
                // On the hour (e.g., 19:00, 20:00)
                nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)
            } else {
                // Specific minutes past the hour (e.g., 18:15, 19:15)
                nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: alarmMinutes, second: 0), matchingPolicy: .nextTime)
            }
            
            guard let alarmTime = nextAlarmTime else { return }
            
            let timeInterval = alarmTime.timeIntervalSince(now)
            
            alarmTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                self.playBeep()
                self.setupAlarmTimer() // Schedule next alarm
            }
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
    
    @objc private func setTimer15() {
        if isTimerEnabled && intervalMinutes == 15 {
            isTimerEnabled = false
        } else {
            isTimerEnabled = true
            intervalMinutes = 15
        }
        setupIntervalTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setTimer30() {
        if isTimerEnabled && intervalMinutes == 30 {
            isTimerEnabled = false
        } else {
            isTimerEnabled = true
            intervalMinutes = 30
        }
        setupIntervalTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setTimer60() {
        if isTimerEnabled && intervalMinutes == 60 {
            isTimerEnabled = false
        } else {
            isTimerEnabled = true
            intervalMinutes = 60
        }
        setupIntervalTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setAlarm15() {
        if isAlarmEnabled && alarmMinutes == 15 {
            isAlarmEnabled = false
        } else {
            isAlarmEnabled = true
            alarmMinutes = 15
        }
        setupAlarmTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setAlarm30() {
        if isAlarmEnabled && alarmMinutes == 30 {
            isAlarmEnabled = false
        } else {
            isAlarmEnabled = true
            alarmMinutes = 30
        }
        setupAlarmTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setAlarm45() {
        if isAlarmEnabled && alarmMinutes == 45 {
            isAlarmEnabled = false
        } else {
            isAlarmEnabled = true
            alarmMinutes = 45
        }
        setupAlarmTimer()
        updateMenuCheckmarks()
    }
    
    @objc private func setAlarm00() {
        if isAlarmEnabled && alarmMinutes == 0 {
            isAlarmEnabled = false
        } else {
            isAlarmEnabled = true
            alarmMinutes = 0
        }
        setupAlarmTimer()
        updateMenuCheckmarks()
    }
    
    private func updateInterval(_ minutes: Int) {
        intervalMinutes = minutes
        setupHourlyTimer()
        updateMenuCheckmarks()
    }
    
    private func updateMenuCheckmarks() {
        guard let menu = statusItem?.menu else { return }
        
        for item in menu.items {
            // Clear all checkmarks first
            if item.title.hasPrefix("  ") {
                item.state = .off
            }
            
            // Set checkmarks for enabled timers
            if isTimerEnabled {
                if (item.title == "  Every 15 minutes" && intervalMinutes == 15) ||
                   (item.title == "  Every 30 minutes" && intervalMinutes == 30) ||
                   (item.title == "  Every 1 hour" && intervalMinutes == 60) {
                    item.state = .on
                }
            }
            
            // Set checkmarks for enabled alarms
            if isAlarmEnabled {
                if (item.title == "  At X:15" && alarmMinutes == 15) ||
                   (item.title == "  At X:30" && alarmMinutes == 30) ||
                   (item.title == "  At X:45" && alarmMinutes == 45) ||
                   (item.title == "  At X:00" && alarmMinutes == 0) {
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
        intervalTimer?.invalidate()
        alarmTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
