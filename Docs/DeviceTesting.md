# Move Forward physical-device testing

Use a paired iPhone and Apple Watch. These checks cannot be completed in this Linux environment.

## Notifications and haptics

1. Enable Move Forward notifications on Apple Watch.
2. Enable haptics. Use Silent Mode for a quiet clinic cue.
3. Confirm Focus modes can still suppress alerts; the app cannot override that.
4. Send **Test watch alert** from iPhone Settings and confirm a wrist cue when the Watch is reachable.

## Start on Watch, iPhone elsewhere

1. Open Move Forward on Apple Watch.
2. Start **Move Forward** (20 minutes).
3. Confirm the first component is **Greet and Smile!** and a start haptic plays if permitted.
4. Leave the iPhone in another room.
5. Confirm transitions at 1:00, 5:00, 7:00, 11:00, 13:00, 14:00, 15:00, and completion at 20:00 with **Dunzo! Good job!**
6. Confirm each notification title matches the component (or completion message).
7. Confirm the EXIT ROOM component uses amber plus an EXIT ROOM label.
8. Confirm post-room copy after that milestone.
9. Reopen the Watch app mid-session and confirm remaining times reconstruct from timestamps.

## Start on iPhone, Watch nearby

1. Start a balanced template on iPhone.
2. Confirm the iPhone session starts immediately.
3. Confirm the Watch receives the session, schedules remaining alerts, and shows the same component.
4. If the Watch is unreachable, confirm iPhone shows a connection/pending status instead of claiming the Watch is ready.

## Cancellation and statistics

1. End a visit early. Confirm it does not increment Today.
2. Restart a visit. Confirm the previous attempt is not counted.
3. Let a visit complete naturally. Confirm Today increments once even after phone/watch sync.
4. Confirm most-used templates come from completed visits only.

## Quick launch

1. Complication: opens the template chooser; does not auto-start.
2. Siri / Shortcuts: “Choose a visit in Move Forward” opens the chooser.
3. Action Button on compatible watches: assign the shortcut and confirm it opens the chooser.

## Displays

1. Check a small Watch face and a large Watch face.
2. Check Dynamic Type, Reduce Motion, and Increase Contrast on iPhone.
3. Check Light and Dark appearance.

## Editing

1. Create, rename, duplicate, reorder, and delete templates.
2. Add, delete, reorder, and rename components.
3. Change total duration and component durations in 30-second steps.
4. Unbalance a template, confirm the discrepancy, Fit to total, and Use component total.
5. Confirm an unbalanced template cannot start.
6. Confirm editing a template does not change an already running session.
