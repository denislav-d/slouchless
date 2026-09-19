# Slouchless

Slouchless is a macOS menu bar app that helps you notice posture drift while wearing AirPods or other headphones with head tracking. It reads headphone motion, calibrates your comfortable upright posture, then classifies live movement as good, warning, or bad posture.

## What It Does

- Streams pitch, roll, and yaw from `CMHeadphoneMotionManager`
- Saves a three-second calibration profile in `UserDefaults`
- Smooths posture deltas before publishing state changes
- Shows live status from the menu bar
- Sends a local notification after sustained bad posture

## Preview
<img width="283" height="459" alt="Screenshot 2026-09-20 at 01 10 03" src="https://github.com/user-attachments/assets/18bcfad7-b6c0-4751-9889-e3a8dece8f8a" />
<img width="283" height="457" alt="Screenshot 2026-09-20 at 01 09 08" src="https://github.com/user-attachments/assets/ed9b77e0-0bc0-4b7c-9b30-7669887a0b42" />


## Project Map

- `SlouchlessApp.swift` creates the menu bar app and status icon.
- `MenuBarView.swift` contains the compact monitoring UI.
- `AirPodsMotionManager.swift` wraps Core Motion headphone tracking.
- `CalibrationManager.swift` captures and persists the baseline profile.
- `PostureAnalyzer.swift` smooths motion and classifies posture state.
- `PostureViewModel.swift` connects motion, calibration, analysis, and notifications.

## Running

Open `Slouchless.xcodeproj` in Xcode, select the `Slouchless` scheme, then run the app on macOS 14 or newer.

For live tracking, connect AirPods or compatible headphones that support head-tracked motion. Use **Start Monitoring**, hold a comfortable upright posture, then choose **Calibrate Good Posture**.

## Testing

Run the test target from Xcode, or use:

```sh
xcodebuild test -scheme Slouchless -destination 'platform=macOS'
```
