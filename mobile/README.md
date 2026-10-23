# IronLog Mobile

Native Flutter client for the same API and account as the Angular frontend.

## Run

```sh
cd mobile
flutter pub get
flutter run
```

The default API is the existing HTTPS Azure deployment:
`https://ironlog-app-george-c0hdakfvh6ggg2dp.italynorth-01.azurewebsites.net`.
Sign in with your Azure IronLog account. Tokens are stored in secure storage,
separately for each API environment. No credentials are included in the app.

VS Code launch configurations include Azure (default), local iOS and local
Android. To override the API manually:

```sh
flutter run --dart-define=API_BASE_URL=http://localhost:5090
# Android emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5090
```

Local HTTP is permitted only in debug builds. Production uses HTTPS.
Xcode must be selected as the active developer directory for iOS builds:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## Screens

Actual Android screenshots of progress, exercises, and workout history are now
included in the [main README](../README.md#screenshots), with the original PNGs
in [docs/screenshots](../docs/screenshots/README.md).

Login/registration, exercise progress, exercises and muscle groups with
create/edit dialogs and delete confirmation, paginated workout history with
a modal workout form, body-weight history, and settings.

Colors and Greek/English copy follow the Angular app. Six accent palettes,
language and a per-account profile picture are stored locally on the device,
like the web client's browser-local preferences. Photos are not uploaded to
Azure or synchronized between devices.

The progress calculations match the Angular dashboard: warmups are excluded;
working weight and reps use the maximum per workout; volume sums weight x reps.
Percentage changes compare the first and latest records, with no percentage
for a zero baseline or fewer than two records.

## Verify

```sh
flutter analyze
flutter test
```

## Android

Requires an Android SDK with API 36, Build Tools 36, NDK 28.2.13676358,
platform-tools and command-line tools, plus a JDK supported by Gradle 9.3.1.
The app supports Android 7.0 (API 24) or newer. Review any SDK license prompts
with `flutter doctor --android-licenses` before accepting them.

```sh
flutter build apk --release
flutter devices
flutter install --release -d <android-device-id>
```

The universal APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.
It uses Azure by default, not the local API. For a physical phone, enable USB
debugging and authorize the Mac, or transfer the APK and permit installation
from the app used to open it.

This is an optimized test build signed with the local Android development key.
It is suitable for direct testing, not a Google Play release. Keep the same key
to install future updates without uninstalling the app. Before Play distribution,
configure a private upload keystore and Play App Signing, then build an AAB.
Do not commit keystores or `key.properties`.

Android uses the system photo picker, an IronLog adaptive launcher icon and
a dark splash screen. Automatic app backup is disabled to avoid restoring
encrypted login data without its device-specific Android Keystore key.
