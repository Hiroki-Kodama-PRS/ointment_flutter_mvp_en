# Ointment Care React Native MVP

React Native / Expo rewrite of the ointment usage tracker MVP.

This folder is intentionally separate from the Flutter app in the repository
root. Keep React Native work inside `react_native_ointment_care/` so the two
implementations can be compared or removed independently.

## Implemented

- Manual ointment usage logging
- Splash, login, user registration, password reset, and healthcare data consent
  screens
- Dashboard metrics for today, the last 7 days, adherence, and badges
- Usage history with amount, streak, itchy/red scores, and photo diary status
- Skin status logs with photo picker
- Swipe sliders for itchy and red scores
- Achievement badges
- Daily target and 24-hour reminder setting
- Local on-device storage with AsyncStorage

## Replit Development

Import the repository into Replit, then open a shell in this folder:

```bash
cd react_native_ointment_care
npm install
npx expo install --fix
npm run web
```

Replit should expose the Expo web preview. This is the fastest place to develop
layout and logic.

## iPhone Development

On a Mac with Xcode installed:

```bash
cd react_native_ointment_care
npm install
npx expo install --fix
npm run ios
```

For real-device testing and App Store preparation, use Expo development builds
or EAS Build:

```bash
npx expo prebuild
npx expo run:ios
```

Replit cannot build signed App Store archives because iOS signing requires
macOS and Xcode. It can still be the main coding and web-preview environment.

## App Store Notes

- Current bundle identifier: `com.pharosense.ointmentcare`
- Current app name: `Ointment Care`
- Current orientation: portrait
- iOS photo library and camera purpose strings are defined in `app.json`
- Safe-area layout is enabled to avoid the iPhone speaker / Dynamic Island area
- Replace placeholder metadata and app icons before TestFlight
- Replace the local MVP auth flow with production authentication before release
- Add privacy labels and a medical-use disclaimer before submission

## Useful Checks

```bash
npm install
npx expo-doctor
npm run web
```

Expo SDK 55 targets React Native 0.83 and React 19.2. See the Expo SDK
reference for the current compatibility table:

https://docs.expo.dev/versions/latest/
