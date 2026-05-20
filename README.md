# Ointment Care Flutter MVP

Flutter MVP for tracking ointment usage and skin status. The project now keeps
the Flutter Web MVP intact while preparing the same codebase for iPhone
development.

## Implemented

- Manual ointment usage logging
- Dashboard for today, the last 7 days, and weekly totals
- Usage history
- Skin status logs
- Achievement badges
- Daily target and reminder schedule settings
- Local on-device storage with `shared_preferences`

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Replit

Replit is useful for web previews and shared development, but it cannot build or
sign the final iOS app because App Store archives require macOS and Xcode.

See [docs/iphone_replit_release_plan.md](docs/iphone_replit_release_plan.md).

## React Native Rewrite

A separate Expo / React Native version lives in
[react_native_ointment_care](react_native_ointment_care). It is intentionally
kept outside the Flutter folders so the two implementations do not mix.
The React Native MVP now includes splash, local auth, data consent, safe-area
layout, richer history rows, and swipe controls for itchy/red scores.
For Replit testing, the onboarding gate is currently disabled so the app opens
directly to the main screen.

For a Replit web preview:

```bash
cd react_native_ointment_care
npm install
npx expo install --fix
npm run web
```

## iPhone

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter pub get
flutter doctor
flutter run -d ios
```

For a real device or App Store signing, open `ios/Runner.xcworkspace` in Xcode
and confirm the Apple Developer Team.

## Verification

```bash
flutter analyze
flutter test
flutter build web
```

## GitHub Pages

This repository deploys Flutter Web to GitHub Pages through GitHub Actions.

1. Add this folder as a repository in GitHub Desktop, or use `gh repo create`
2. Publish it to GitHub
3. In the GitHub repository, open `Settings > Pages`
4. Set `Build and deployment` source to `GitHub Actions`
5. Push to the `main` branch

The expected public URL is:

```text
https://Hiroki-Kodama-PRS.github.io/ointment_flutter_mvp_en/
```

## Next Phase

- Replit web preview setup
- iPhone simulator and real-device testing
- App Store metadata, screenshots, privacy labels, and TestFlight
- Photo storage
- Bluetooth LE device integration
- Notifications
- Clinician sharing reports
- Authentication and cloud sync
- Security and regulatory requirements for medical data
