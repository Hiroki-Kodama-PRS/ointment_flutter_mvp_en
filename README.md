# Ointment Care Flutter MVP (English)

English Flutter / VS Code MVP for tracking ointment usage and skin status.

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
cd /Users/hirokikodama/ointment_flutter_mvp_en
code .
flutter run -d chrome
```

To run as a macOS app:

```bash
flutter run -d macos
```

To run on an iPhone simulator, install the full Xcode package first.

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter run -d ios
```

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

- Photo storage
- Bluetooth LE device integration
- Notifications
- Clinician sharing reports
- Authentication and cloud sync
- Security and regulatory requirements for medical data
