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
