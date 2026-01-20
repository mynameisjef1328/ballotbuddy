# Ballot Buddy iOS App

Native iOS wrapper for Ballot Buddy with enhanced native features to meet App Store review guideline 4.2.2 (Minimum Functionality).

## Native Features Implemented

### 1. Local Push Notifications for Election Reminders
- **Permission Handling**: Requests notification permissions with clear value proposition
- **Multiple Reminder Types**:
  - 1 week before election
  - 1 day before election
  - Morning of election day (8 AM)
- **User-Friendly Messaging**: "Never miss an election - we'll remind you when it's time to vote"
- **Persistent Storage**: Reminder preferences stored in UserDefaults
- **Implementation**: `NotificationManager.swift` using `UNUserNotificationCenter`

### 2. Calendar Integration
- **EventKit Integration**: Native calendar access using EventKit framework
- **Permission Handling**: Graceful permission requests with fallback messaging
- **Rich Event Details**:
  - Election name and date
  - Polling location (if available)
  - Helpful notes and reminders
  - Automatic alarms (1 week before, morning of)
- **iOS Version Support**: Compatible with iOS 15+ with iOS 17 support for full access
- **Implementation**: `CalendarManager.swift` with EKEventStore

### 3. Haptic Feedback
- **Comprehensive Haptics**: Multiple feedback types for different interactions
  - Button taps (soft/light haptic)
  - Important actions (medium haptic)
  - Success states (success notification)
  - Navigation (light haptic)
  - Selection changes (selection haptic)
- **Context-Aware**: Different haptics for different actions (e.g., state selection, reminder scheduled, calendar added)
- **Implementation**: `HapticManager.swift` using UIImpactFeedbackGenerator

## Architecture

### Native iOS Layer (Swift)
- **BallotBuddyApp.swift**: Main app entry point with SwiftUI and notification delegate
- **ContentView.swift**: SwiftUI view containing WKWebView
- **NativeFeaturesBridge.swift**: JavaScript-to-Native communication bridge
- **Manager Classes**: NotificationManager, CalendarManager, HapticManager

### Web Layer (JavaScript)
- **NativeBridge Object**: JavaScript API for calling native functions
- **Callback System**: Async communication with promise-like callbacks
- **Graceful Degradation**: Works in browser with console logging when native bridge unavailable

### Communication Flow
```
JavaScript (index.html)
    ↓
NativeBridge.sendMessage()
    ↓
WKScriptMessageHandler (NativeFeaturesBridge.swift)
    ↓
Native Manager (Notification/Calendar/Haptic)
    ↓
Callback Response
    ↓
JavaScript Callback Function
```

## Key Files

### iOS Native Code
- `BallotBuddy/BallotBuddyApp.swift` - App lifecycle and notification handling
- `BallotBuddy/ContentView.swift` - WKWebView container
- `BallotBuddy/NativeFeaturesBridge.swift` - JavaScript bridge
- `BallotBuddy/NotificationManager.swift` - Notification scheduling
- `BallotBuddy/CalendarManager.swift` - Calendar event management
- `BallotBuddy/HapticManager.swift` - Haptic feedback
- `BallotBuddy/Info.plist` - Permissions and configuration

### Web Content
- `index.html` - Updated with native bridge integration

### Xcode Project
- `BallotBuddy.xcodeproj/project.pbxproj` - Xcode project file

## Permissions Required

### Notifications
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Never miss an election - we'll remind you when it's time to vote and help you stay informed about important deadlines.</string>
```

### Calendar
```xml
<key>NSCalendarsUsageDescription</key>
<string>Ballot Buddy needs access to your calendar to add election date reminders so you never miss an important voting deadline.</string>

<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>Add election dates directly to your calendar for easy tracking of voting deadlines.</string>
```

## How to Build

1. Open `BallotBuddy.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on simulator or device (iOS 15.0+)

## User Experience Flow

### Setting Election Reminders
1. User taps "Add Election Reminders" button
2. App requests notification permission with clear value proposition
3. User enters election name and date
4. App schedules 3 notifications (1 week, 1 day, morning of)
5. App offers to add event to calendar
6. Success haptic and confirmation toast

### Calendar Integration
1. User confirms calendar addition
2. App requests calendar permission
3. Event created with:
   - Election name
   - All-day event on election date
   - Helpful notes and voting reminders
   - 2 alarms (1 week before, morning of)
4. Success haptic and confirmation

### Haptic Feedback
- Every button tap provides subtle tactile feedback
- State selection triggers selection haptic
- Important actions (like registration) get stronger haptic
- Success actions get success notification haptic

## App Store Compliance

This implementation addresses App Store rejection for guideline 4.2.2 by:

1. **Native Functionality**: Uses native iOS APIs (UNUserNotificationCenter, EventKit, UIFeedbackGenerator)
2. **Value Beyond Web**: Provides features not available in mobile Safari (local notifications, calendar integration, haptics)
3. **Platform Integration**: Integrates with iOS system features (Calendar app, Notification Center)
4. **Enhanced UX**: Native haptic feedback for all interactions
5. **Permission Handling**: Proper iOS permission flows with user-friendly messaging

## Technical Highlights

- **iOS 15+ Support**: Modern SwiftUI with backwards compatibility
- **WKWebView**: Efficient web content loading with JavaScript bridge
- **Async Communication**: Callback-based bridge for async operations
- **Error Handling**: Graceful fallbacks for permission denials
- **User Preferences**: Persistent storage of reminder preferences
- **Comprehensive Haptics**: Context-aware tactile feedback throughout

## Testing Checklist

- [ ] Notification permission request shows custom message
- [ ] Notifications scheduled for correct dates/times
- [ ] Calendar permission request works
- [ ] Calendar events created with correct details
- [ ] Haptic feedback on all button taps
- [ ] Different haptics for different actions
- [ ] Graceful handling of permission denials
- [ ] Web content loads correctly in WKWebView
- [ ] JavaScript bridge communication works
- [ ] App works on iOS 15, 16, and 17

## Next Steps for App Store Submission

1. Add app icon in Assets.xcassets
2. Configure bundle identifier
3. Set up code signing
4. Add screenshots showing native features
5. Update App Store description to highlight native functionality
6. Test on physical device
7. Submit for review with notes about native features

---

Built with Swift, SwiftUI, and WKWebView
Designed to pass App Store review guideline 4.2.2
