import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem?
    private var audioPlayer: AVAudioPlayer?
    
    // Multiple timers support
    private var activeTimers: [Timer] = []
    private var enabledIntervals: Set<Int> = []
    
    // Multiple alarms support  
    private var activeAlarms: [Timer] = []
    private var enabledAlarmMinutes: Set<Int> = [0] // Default: hourly (X:00)
    
    // Countdown display
    private var countdownTimer: Timer?
    private var timerStartTimes: [Int: Date] = [:]
    private var menuUpdateTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBarItem()
        setupHourlyTimer()
        startCountdownUpdater()
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
        menu.delegate = self
    }
    
    private func setupHourlyTimer() {
        setupAllTimers()
        setupAllAlarms()
    }
    
    private func setupAllTimers() {
        // Invalidate all existing timers
        activeTimers.forEach { $0.invalidate() }
        activeTimers.removeAll()
        
        // Remove start times for intervals that are no longer enabled
        let disabledIntervals = Set(timerStartTimes.keys).subtracting(enabledIntervals)
        for interval in disabledIntervals {
            timerStartTimes.removeValue(forKey: interval)
        }
        
        // Create new timers for each enabled interval
        for interval in enabledIntervals {
            let intervalSeconds = TimeInterval(interval * 60)
            
            // Only set start time if not already set (preserve existing timers)
            if timerStartTimes[interval] == nil {
                timerStartTimes[interval] = Date()
            }
            
            let timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
                self.playBeep()
                self.timerStartTimes[interval] = Date() // Reset start time after beep
            }
            activeTimers.append(timer)
        }
    }
    
    private func setupAllAlarms() {
        // Invalidate all existing alarms
        activeAlarms.forEach { $0.invalidate() }
        activeAlarms.removeAll()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create new alarms for each enabled time
        for minutes in enabledAlarmMinutes {
            var nextAlarmTime: Date?
            
            if minutes == 0 {
                // On the hour (e.g., 19:00, 20:00)
                nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)
            } else {
                // Specific minutes past the hour (e.g., 18:15, 19:15)
                nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: minutes, second: 0), matchingPolicy: .nextTime)
            }
            
            guard let alarmTime = nextAlarmTime else { continue }
            
            let timeInterval = alarmTime.timeIntervalSince(now)
            
            let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                self.playBeep()
                self.scheduleNextAlarm(for: minutes)
            }
            activeAlarms.append(timer)
        }
    }
    
    private func scheduleNextAlarm(for minutes: Int) {
        // Only reschedule if this alarm is still enabled
        guard enabledAlarmMinutes.contains(minutes) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        var nextAlarmTime: Date?
        
        if minutes == 0 {
            nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)
        } else {
            nextAlarmTime = calendar.nextDate(after: now, matching: DateComponents(minute: minutes, second: 0), matchingPolicy: .nextTime)
        }
        
        guard let alarmTime = nextAlarmTime else { return }
        
        let timeInterval = alarmTime.timeIntervalSince(now)
        
        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.playBeep()
            self.scheduleNextAlarm(for: minutes)
        }
        activeAlarms.append(timer)
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
        toggleTimer(interval: 15)
    }
    
    @objc private func setTimer30() {
        toggleTimer(interval: 30)
    }
    
    @objc private func setTimer60() {
        toggleTimer(interval: 60)
    }
    
    @objc private func setAlarm15() {
        toggleAlarm(minutes: 15)
    }
    
    @objc private func setAlarm30() {
        toggleAlarm(minutes: 30)
    }
    
    @objc private func setAlarm45() {
        toggleAlarm(minutes: 45)
    }
    
    @objc private func setAlarm00() {
        toggleAlarm(minutes: 0)
    }
    
    private func toggleTimer(interval: Int) {
        if enabledIntervals.contains(interval) {
            enabledIntervals.remove(interval)
            timerStartTimes.removeValue(forKey: interval)
        } else {
            enabledIntervals.insert(interval)
        }
        setupAllTimers()
        updateMenuCheckmarks()
    }
    
    private func toggleAlarm(minutes: Int) {
        if enabledAlarmMinutes.contains(minutes) {
            enabledAlarmMinutes.remove(minutes)
        } else {
            enabledAlarmMinutes.insert(minutes)
        }
        setupAllAlarms()
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
            if (item.title == "  Every 15 minutes" && enabledIntervals.contains(15)) ||
               (item.title == "  Every 30 minutes" && enabledIntervals.contains(30)) ||
               (item.title == "  Every 1 hour" && enabledIntervals.contains(60)) {
                item.state = .on
            }
            
            // Set checkmarks for enabled alarms
            if (item.title == "  At X:15" && enabledAlarmMinutes.contains(15)) ||
               (item.title == "  At X:30" && enabledAlarmMinutes.contains(30)) ||
               (item.title == "  At X:45" && enabledAlarmMinutes.contains(45)) ||
               (item.title == "  At X:00" && enabledAlarmMinutes.contains(0)) {
                item.state = .on
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
    
    private func startCountdownUpdater() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimerHeader()
        }
    }
    
    private func updateTimerHeader() {
        guard let menu = statusItem?.menu else { return }
        
        // Find and update the timer header menu item
        for item in menu.items {
            if item.title.hasPrefix("Timer") {
                let countdownText = getNextTimerCountdown()
                let absoluteTime = getNextTimerAbsoluteTime()
                if countdownText.isEmpty {
                    item.title = "Timer"
                } else {
                    item.title = "Timer - Next: \(countdownText) (\(absoluteTime))"
                }
                break
            }
        }
        
        // Find and update the alarm header menu item
        for item in menu.items {
            if item.title.hasPrefix("Alarm") {
                let alarmText = getNextAlarmCountdown()
                if alarmText.isEmpty {
                    item.title = "Alarm"
                } else {
                    item.title = "Alarm - Next: \(alarmText)"
                }
                break
            }
        }
    }
    
    private func getNextTimerCountdown() -> String {
        guard !enabledIntervals.isEmpty else { 
            return ""
        }
        
        let now = Date()
        var nextBeepTime: TimeInterval = Double.greatestFiniteMagnitude
        
        // Check interval timers only
        for interval in enabledIntervals {
            guard let startTime = timerStartTimes[interval] else { 
                continue 
            }
            
            let intervalSeconds = TimeInterval(interval * 60)
            let elapsedTime = now.timeIntervalSince(startTime)
            let timeUntilNext = intervalSeconds - elapsedTime.truncatingRemainder(dividingBy: intervalSeconds)
            
            // Ensure we don't show 0 or negative time
            let adjustedTime = timeUntilNext <= 0 ? intervalSeconds : timeUntilNext
            
            if adjustedTime < nextBeepTime {
                nextBeepTime = adjustedTime
            }
        }
        
        if nextBeepTime == Double.greatestFiniteMagnitude {
            return ""
        }
        
        // Format time as MM:SS
        let minutes = Int(nextBeepTime) / 60
        let seconds = Int(nextBeepTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getNextTimerAbsoluteTime() -> String {
        guard !enabledIntervals.isEmpty else { 
            return ""
        }
        
        let now = Date()
        var nextBeepTime: TimeInterval = Double.greatestFiniteMagnitude
        
        // Check interval timers only
        for interval in enabledIntervals {
            guard let startTime = timerStartTimes[interval] else { 
                continue 
            }
            
            let intervalSeconds = TimeInterval(interval * 60)
            let elapsedTime = now.timeIntervalSince(startTime)
            let timeUntilNext = intervalSeconds - elapsedTime.truncatingRemainder(dividingBy: intervalSeconds)
            
            // Ensure we don't show 0 or negative time
            let adjustedTime = timeUntilNext <= 0 ? intervalSeconds : timeUntilNext
            
            if adjustedTime < nextBeepTime {
                nextBeepTime = adjustedTime
            }
        }
        
        if nextBeepTime == Double.greatestFiniteMagnitude {
            return ""
        }
        
        // Calculate absolute time when beep happens
        let beepTime = now.addingTimeInterval(nextBeepTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: beepTime)
    }
    
    private func getNextAlarmCountdown() -> String {
        guard !enabledAlarmMinutes.isEmpty else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        var nextAlarmTime: Date?
        
        // Find the nearest alarm time from all enabled alarms
        for minutes in enabledAlarmMinutes {
            var candidateTime: Date?
            
            if minutes == 0 {
                // On the hour (e.g., 19:00, 20:00)
                candidateTime = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)
            } else {
                // Specific minutes past the hour (e.g., 18:15, 19:15)
                candidateTime = calendar.nextDate(after: now, matching: DateComponents(minute: minutes, second: 0), matchingPolicy: .nextTime)
            }
            
            if let candidate = candidateTime {
                if nextAlarmTime == nil || candidate < nextAlarmTime! {
                    nextAlarmTime = candidate
                }
            }
        }
        
        guard let alarmTime = nextAlarmTime else {
            return ""
        }
        
        let timeInterval = alarmTime.timeIntervalSince(now)
        
        // Format countdown time as MM:SS or HH:MM for longer times
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        let countdownText: String
        if hours > 0 {
            countdownText = String(format: "%d:%02d", hours, minutes)
        } else {
            countdownText = String(format: "%d:%02d", minutes, seconds)
        }
        
        // Format absolute time (HH:MM)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let absoluteTime = formatter.string(from: alarmTime)
        
        return "\(countdownText) (\(absoluteTime))"
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        // Start frequent updates when menu is open
        menuUpdateTimer?.invalidate()
        
        // Create timer on main run loop to ensure it works during menu interaction
        menuUpdateTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTimerHeader()
            }
        }
        
        // Add to common run loop modes so it continues during menu tracking
        RunLoop.main.add(menuUpdateTimer!, forMode: .common)
        
        // Update immediately
        updateTimerHeader()
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Stop frequent updates when menu closes
        menuUpdateTimer?.invalidate()
        menuUpdateTimer = nil
    }
    
    @objc private func quitApp() {
        activeTimers.forEach { $0.invalidate() }
        activeAlarms.forEach { $0.invalidate() }
        countdownTimer?.invalidate()
        menuUpdateTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
