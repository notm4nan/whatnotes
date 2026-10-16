<img width="256" height="256" alt="appicon" src="https://github.com/user-attachments/assets/883a6c6e-8990-4db5-9a3d-0d9bb4d5e737" />

# WhatNotes

WhatNotes is an Android-first Flutter inbox for saving notes, links, and images. It supports email/username authentication, private cloud storage with Firebase, search, tags, archive/restore, delete, and light, dark, and retro themes.

## Supported platform

- Android devices

## Requirements

- Flutter SDK and Dart
- Android Studio or an Android device/emulator
- A Firebase project with Email/Password Authentication and Cloud Firestore enabled


## Download APK

[whatnote.apk](https://github.com/notm4nan/whatnotes/blob/main/build/app/outputs/flutter-apk/whatnotes.apk)


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
