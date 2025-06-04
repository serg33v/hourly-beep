# Hour Beep

A powerful and flexible macOS menu bar application that provides comprehensive time management with **multiple simultaneous timers and alarms** to help you stay productive and aware of time.

## Features

- 🔔 Lives in your macOS menu bar - unobtrusive and always accessible
- ⏰ **Multiple Timer Support**: Run multiple interval timers simultaneously (15 min, 30 min, 1 hour)
- 🕐 **Multiple Alarm Support**: Set multiple time-based alarms simultaneously (X:00, X:15, X:30, X:45)
- 🔄 **Unlimited Combinations**: Mix and match any combination of timers and alarms
- ✅ **Independent Toggle**: Click any timer or alarm to enable/disable it independently
- 🎵 Custom sound support (MP3 format)
- 🎛️ Volume control (80% by default)
- 🖱️ Manual beep trigger
- 🌙 Automatic dark/light mode icon adaptation

## Installation

### Building from Source

1. **Prerequisites**
   - macOS 13.0 or later
   - Xcode 15.0 or later

2. **Clone and Build**
   ```bash
   git clone <repository-url>
   cd hour-beep
   open HourBeep.xcodeproj
   ```

3. **Build and Run**
   - Press `⌘+R` in Xcode to build and run
   - The app will appear in your menu bar as a bell icon

## Usage

### Basic Operation

1. **Launch the app** - A bell icon will appear in your menu bar
2. **Click the icon** to access the menu with these options:
   - **Beep** - Trigger an immediate beep sound
   - **Timer** _(section header)_
     - Every 15 minutes - Toggle 15-minute interval timer
     - Every 30 minutes - Toggle 30-minute interval timer  
     - Every 1 hour - Toggle 1-hour interval timer
   - **Alarm** _(section header)_
     - At X:15 - Toggle alarm at 15 minutes past each hour
     - At X:30 - Toggle alarm at 30 minutes past each hour
     - At X:45 - Toggle alarm at 45 minutes past each hour
     - At X:00 - Toggle alarm on the hour (default: on)
   - **Quit Hour Beep** - Exit the application

### Menu Options

| Option | Description | Toggle Behavior |
|--------|-------------|-----------------|
| Beep | Plays the beep sound immediately | One-time action |
| **Timer** | **Interval-based notifications** | |
| → Every 15 minutes | Beep every 15 minutes continuously | Click to enable/disable |
| → Every 30 minutes | Beep every 30 minutes continuously | Click to enable/disable |
| → Every 1 hour | Beep every hour continuously | Click to enable/disable |
| **Alarm** | **Time-based notifications** | |
| → At X:15 | Beep at X:15 (18:15, 19:15, 20:15, etc.) | Click to enable/disable |
| → At X:30 | Beep at X:30 (18:30, 19:30, 20:30, etc.) | Click to enable/disable |
| → At X:45 | Beep at X:45 (18:45, 19:45, 20:45, etc.) | Click to enable/disable |
| → At X:00 | Beep at X:00 (19:00, 20:00, 21:00, etc.) (default: on) | Click to enable/disable |
| Quit Hour Beep | Closes the application | Exit app |

Active options will show a checkmark (✓) next to them. Multiple options can be enabled simultaneously.

### Timer and Alarm Modes

**Multiple Timer Support** (Interval-based): 
- Run **multiple interval timers simultaneously**
- Each timer repeats every X minutes from when you enable it
- Example: Enable both "Every 15 minutes" and "Every 30 minutes" simultaneously
- All enabled timers run independently and will beep at their respective intervals

**Multiple Alarm Support** (Time-based):
- Set **multiple time-based alarms simultaneously** 
- Each alarm beeps at specific clock times regardless of when enabled
- Example: Enable "At X:15" and "At X:45" to beep at both quarter-past and quarter-to each hour
- Available times: X:00, X:15, X:30, X:45 (quarter-hour intervals)
- All enabled alarms run independently

**Unlimited Combinations**:
- **Any combination possible**: Mix multiple timers with multiple alarms
- Example: "Every 15 minutes" + "Every 1 hour" + "At X:00" + "At X:30" all active
- You'll get beeps from all enabled systems independently
- Maximum flexibility for any workflow or schedule

## Customization

### Custom Sound

1. Add your own `beep.mp3` file to the project
2. In Xcode, drag the MP3 file into the project navigator
3. Make sure "Add to target: HourBeep" is checked
4. Rebuild the app

**Supported formats:** MP3

### Volume Control

The beep volume is set to 80% by default. To change it:

1. Open `AppDelegate.swift`
2. Find the line `audioPlayer?.volume = 0.8`
3. Change `0.8` to your desired value (0.0 to 1.0)
4. Rebuild the app

## Technical Details

### System Requirements

- **macOS:** 13.0 (Ventura) or later
- **Architecture:** Universal (Intel and Apple Silicon)

### Frameworks Used

- **Cocoa** - Core macOS application framework
- **AVFoundation** - Audio playback
- **Foundation** - Timer and system integration

### App Behavior

- **Menu Bar Only:** The app runs as a menu bar utility (no dock icon)
- **Background Operation:** Continues running and beeping even when other apps are in focus
- **System Integration:** Respects system volume settings and Do Not Disturb mode
- **Memory Efficient:** Minimal resource usage with timer-based operation

### File Structure

```
HourBeep/
├── HourBeep.xcodeproj/     # Xcode project file
├── HourBeep/
│   ├── main.swift          # App entry point
│   ├── AppDelegate.swift   # Main app logic and UI
│   ├── Info.plist         # App configuration
│   ├── beep.mp3           # Custom sound file (optional)
│   └── Assets.xcassets/   # App assets
└── README.md              # This file
```

## Development

### Key Components

- **NSStatusItem** - Menu bar icon and menu
- **Multiple Timer Management** - Simultaneous interval-based scheduling with independent timers
- **Multiple Alarm Management** - Simultaneous time-based scheduling with calendar integration
- **Calendar** - Alarm time calculations and next occurrence detection
- **AVAudioPlayer** - MP3 sound playback
- **NSSound** - Fallback system sounds
- **Custom Icon** - Programmatically drawn bell icon

### Building

```bash
# Open in Xcode
open HourBeep.xcodeproj

# Or build from command line
xcodebuild -project HourBeep.xcodeproj -scheme HourBeep -configuration Release
```

## Troubleshooting

### No Sound Playing

1. **Check system volume** - Make sure your Mac's volume is turned up
2. **Check sound effects** - Go to System Settings > Sound and ensure alert volume is not muted
3. **Verify MP3 file** - Make sure `beep.mp3` is properly added to the Xcode project
4. **Try fallback sound** - Remove the MP3 file to test with system beep

### App Not Starting

1. **Check macOS version** - Requires macOS 13.0 or later
2. **Rebuild project** - Clean and rebuild in Xcode (⌘+Shift+K, then ⌘+B)
3. **Check permissions** - Allow the app to run in System Settings > Privacy & Security

### Menu Bar Icon Missing

1. **Check running apps** - Look for "HourBeep" in Activity Monitor
2. **Restart app** - Quit and relaunch the application
3. **Check display settings** - Ensure menu bar is visible in System Settings > Control Center

## License

This project is open source. Feel free to modify and distribute according to your needs.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on macOS
5. Submit a pull request

---

**Author:** Created with [Claude Code](https://claude.ai/code)  
**Version:** 2.0 - Multiple Timers & Alarms Support  
**Last Updated:** 2025