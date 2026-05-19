# iPhone and Replit Development Plan

This project is already a multi-platform Flutter app. The current MVP can be
used as the base for iPhone development, but the release path has two separate
tracks:

- Replit: useful for Flutter web previews, code edits, GitHub workflow checks,
  and shared development.
- Mac + Xcode: required for iPhone Simulator, TestFlight, signing, App Store
  archive, and final release.

Replit runs on Linux, so it cannot run Xcode or create a signed iOS archive.

## Current iPhone Readiness

- Flutter iOS project files are present in `ios/`.
- Bundle identifier is currently `com.pharosense.ointmentFlutterMvp`.
- Display name is `Ointment Care`.
- iPhone orientation is portrait-only.
- Local storage uses `shared_preferences`, which works on iOS.
- Skin photos use `image_picker`, which works on iOS with the included privacy
  descriptions.
- Local notifications use `flutter_local_notifications`, which works on iOS
  after the user grants notification permission.

## Replit Setup

1. Import this GitHub repository into Replit.
2. Choose a Flutter template if Replit offers one. If not, use a Nix/Linux
   workspace and install Flutter through Replit's package tools.
3. Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-host 0.0.0.0 --web-port 3000
```

4. Use the Replit web preview to test layout, navigation, local storage,
   photo-picking fallback behavior, and basic flows.

## Local Mac iPhone Setup

Use a Mac with the full Xcode app installed.

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter pub get
flutter doctor
flutter run -d ios
```

For a real iPhone:

```bash
open ios/Runner.xcworkspace
```

Then select the Runner target, confirm the Apple Developer Team, connect the
iPhone, and run from Xcode once to resolve signing prompts.

## App Store Release Checklist

- Confirm final app name, subtitle, category, age rating, and support URL.
- Confirm bundle identifier before uploading the first App Store build.
- Replace placeholder app icons with final icons.
- Prepare screenshots for required iPhone sizes.
- Add privacy nutrition labels in App Store Connect.
- Add a plain-language medical disclaimer if the app remains a self-management
  aid and not a diagnostic or treatment decision tool.
- Decide whether data stays local-only or moves to cloud sync before handling
  personally identifiable medical data.
- Build and distribute through TestFlight before App Store review.

## Recommended Next Development Steps

1. Replace the simulated "Measure" action with manual entry plus a clear mock
   mode label until Bluetooth LE integration is ready.
2. Add exportable CSV/PDF reports for clinician sharing.
3. Add data backup or account sync only after deciding the privacy model.
4. Split `lib/main.dart` into models, services, and screens as features grow.
5. Add golden or integration tests for the main iPhone-sized layouts.
