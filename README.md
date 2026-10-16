# WhatNotes

WhatNotes is an Android-first Flutter inbox for saving notes, links, and images. It supports email/username authentication, private cloud storage with Firebase, search, tags, archive/restore, delete, and light, dark, and retro themes.

## Supported platform

- Android devices

## Requirements

- Flutter SDK and Dart
- Android Studio or an Android device/emulator
- A Firebase project with Email/Password Authentication and Cloud Firestore enabled

## Run locally

```bash
flutter pub get
flutter devices
flutter run -d <android-device-id>
```

## Build an APK

Debug APK:

```bash
flutter build apk --debug
```

Testable release APK:

```bash
flutter build apk --release
```

## Firebase setup

Android Firebase configuration is stored in `android/app/google-services.json`. It contains project identifiers and a client API key, not server credentials. The Firebase project must have:

1. Authentication > Sign-in method > Email/Password enabled.
2. A Cloud Firestore database created.
3. The rules in `firestore.rules` deployed:

```bash
firebase login
firebase use whatnotes-1
firebase deploy --only firestore:rules
```

Firestore rules require every item to have an authenticated owner ID. Users can only read, create, update, archive, restore, or delete their own items.

Do not commit service-account JSON files, private keys, keystores, passwords, or local SDK paths. The repository ignores local Android configuration and generated build output.

The tests cover model serialization, repository CRUD and filtering, persistence, view-model state, and core widget flows.

## Project structure

```text
android/                 Android application and Firebase config
lib/domain/              Domain models and filter options
lib/data/                Firebase/local storage and authentication services
lib/ui/                  Screens, widgets, themes, and view models
test/                    Unit, repository, view-model, and widget tests
firestore.rules          Server-side Firestore ownership rules
firebase.json            Firebase CLI configuration
```
