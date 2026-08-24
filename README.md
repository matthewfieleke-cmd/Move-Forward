# Move Forward

Move Forward is a native iPhone and Apple Watch interval timer for clinic visits.

A physician saves visit templates on iPhone. Each template is an ordered sequence of named components with 30-second durations. Starting a template on iPhone or Apple Watch runs that sequence automatically. Apple Watch buzzes at every component transition and shows the component title.

This is a predetermined interval timer, not a task tracker. It does not detect what the physician is doing, pause, skip, add time, or adapt the schedule.

The visit continues after the physician leaves the exam room. Orders, ticklers, nurse coordination, and documentation are additional timed components.

## Requirements

- Xcode 16 or later
- iOS 18+
- watchOS 11+
- An Apple Developer account for device installation
- A paired iPhone and Apple Watch for the full experience

This repository was assembled in a Linux environment without Xcode. Open the project on a Mac to build, sign, and install it. Do not assume `xcodebuild` has already succeeded.

## Open and sign

1. Open `MoveForward.xcodeproj` in Xcode.
2. Select the **MoveForward** target.
3. In Signing & Capabilities, choose your Team. Leave bundle IDs as:
   - `app.moveforward` (iPhone)
   - `app.moveforward.watchkitapp` (Apple Watch)
   - `app.moveforward.widgets` (Live Activity)
   - `app.moveforward.watchkitapp.widgets` (complication)
4. Repeat signing for the Watch and widget targets if Xcode asks. The project uses Automatic signing and an empty `DEVELOPMENT_TEAM` so you can attach your own team. No one else’s team ID is embedded.
5. Optional: copy `Config/Signing.xcconfig.example` to `Config/Local.xcconfig` (gitignored) and set `DEVELOPMENT_TEAM`.

## Build and install

1. Choose the **MoveForward** scheme.
2. Select your iPhone.
3. Build and run. Xcode should install the iPhone app and the embedded Watch app.
4. If the Watch app does not appear, open the Watch app on iPhone and install **Move Forward**.
5. Grant notification permission on both devices when asked.

To run tests:

```
Product → Test
```

or:

```
xcodebuild test -project MoveForward.xcodeproj -scheme MoveForward -destination 'platform=iOS Simulator,name=iPhone 16'
```

## How it works

Templates, preferences, sessions, and completed-visit counts stay on device. iPhone and Apple Watch synchronize through Watch Connectivity. There is no account, backend, HealthKit, calendar, or EHR integration.

The timer is derived from a persisted start timestamp, component durations, and the current clock. Reopening the Watch app reconstructs the correct component and remaining time.

Watch-local `UNUserNotificationCenter` calendar triggers fire component transitions and the completion message. The app does not keep a background wait-chain running, does not use a fake workout session, and does not rely on iPhone notification mirroring.

If a visit is started on iPhone while the Watch is unreachable, Move Forward shows a connection status and queues the session. It does not claim the Watch is ready.

## Starter templates

The app ships with four editable, duplicable, deletable templates:

| Template | Duration | Completion |
| --- | --- | --- |
| Move Forward | 20 min | Dunzo! Good job! |
| Acute Visit | 15 min | Visit complete. Move forward! |
| Adult Physical | 30 min | Dunzo! Good job! |
| Well-Child Check | 20 min | Visit complete. Great work! |

You can create additional templates from scratch. Invalid templates can be saved as drafts but cannot be started until allocated time matches the planned total, or you use **Fit components to total** / **Use component total**.

## Watch controls

During a session the Watch shows the current component, component remaining time, visit remaining time, component index, progress, and room-exit timing when applicable. Room-exit uses an amber accent plus an EXIT ROOM label, not color alone.

The only session actions are **Start**, **End**, **Restart**, and **Start Next Template**.

Ending or restarting cancels remaining alerts and does not count as a completed visit. Natural completion counts once, even if iPhone and Watch both observe it.

## Complications, Siri, Action Button

The Watch complication, App Shortcuts / Siri, and the Action Button (where available) open the template chooser. They do not silently start a favorite template.

URL scheme: `moveforward://chooser`

## Privacy

Move Forward does not collect patient names, dates of birth, medical record numbers, diagnoses, location, contacts, calendar data, HealthKit data, advertising identifiers, or analytics. It does not require an account.

## Project layout

- `SharedDomain/` — templates, timeline math, validation, session engine, notification planning, sync merge, statistics
- `SharedApp/` — persistence, Watch Connectivity, notification scheduling, Live Activities, App Intents, theme
- `MoveForward/` — iPhone app
- `MoveForwardWatch/` — Apple Watch app
- `MoveForwardWidgets/` — iPhone Live Activity
- `MoveForwardWatchWidgets/` — Watch complication
- `MoveForwardTests/` — unit tests for timelines, validation, sessions, and persistence

Physical-device scenarios are listed in `Docs/DeviceTesting.md`.
