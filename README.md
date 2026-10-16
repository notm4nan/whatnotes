# ByteInbox 📥

> A clean, reliable, single-device offline inbox built with **Flutter & Dart**.  
> No accounts, no servers, no cloud sync—all your notes, web links, and images live directly on your local device.

---

## 🌟 Overview

**ByteInbox** solves the problem of quick-capture information overload. When you need to jot down a fleeting thought, bookmark a website to read later, or stash an image or screenshot, you shouldn't need an account, an internet connection, or complex folder structures. 

ByteInbox provides an offline-first inbox where every item has an explicit type, tags, timestamps, and an archive state, backed by reliable local storage that survives closing and relaunching the app.

---

## 🚀 Key Features

- **Multi-Type Inbox**:
  - 📝 **Notes**: Multi-line thoughts, checklists, or snippets with copy support.
  - 🔗 **Links**: Bookmarks and URLs with automated domain parsing and direct browser launching (`url_launcher`).
  - 🖼️ **Images**: Visual inspiration, screenshots, or photos with interactive pinch-to-zoom (`InteractiveViewer`), device file picker, network image previews, and local file support.
- **Full Item Lifecycle**:
  - **Create**: Dynamic input forms tailored to Notes, Links, or Images.
  - **View & Inspect**: Detail screen with metadata (ID, creation time, last modified time, status).
  - **Open**: Direct browser launch for links, zoomable viewer for images, selectable text for notes.
  - **Edit**: Update titles, content, URLs, and tags with automated `updatedAt` tracking.
  - **Archive & Restore**: Instantly archive items to declutter your inbox, or restore them anytime.
  - **Delete**: Permanent deletion with confirmation safeguards and snackbar feedback.
- **Smart Organization & Discovery**:
  - 🔍 **Real-Time Search**: Instant search matching across titles, content body, and tags simultaneously.
  - 🏷️ **Tagging System**: Add and delete tags easily; deduplicates case-insensitively and strips unwanted `#` characters.
  - 🏷️ **Tag Filter Bar**: Scrollable horizontal tag bar extracted from your saved items.
  - 🗂️ **Type Filters**: Filter by `All`, `Notes`, `Links`, or `Images`.
  - 🗂️ **Inbox vs. Archive Views**: Toggle seamlessly between active inbox items and archived records.
  - ↕️ **Custom Sorting**: Sort by Newest First, Oldest First, Recently Updated, or Alphabetical (A-Z).
- **Rock-Solid Local Persistence**:
  - Built on `SharedPreferences` storing serialized JSON models.
  - Automatic fault-tolerant JSON deserialization with schema fallback.
  - Data survives app termination and relaunches.
- **Intelligent Input Handling**:
  - **Auto-Title Inference**: If you leave the title blank, the app infers one (first line of a note, website domain, or image filename).
  - **URL Normalization**: Automatically prepends `https://` if omitted (e.g. `flutter.dev` → `https://flutter.dev`).
  - **Whitespace Trimming**: Inputs are sanitized and trimmed to avoid blank or messy items.
  - **Broken Image Resilience**: Graceful placeholder and error indicators if an image URL or local file cannot be read.

---

## 📐 Architecture

The app is built following the **Layered MVVM (Model-View-ViewModel)** and **Repository** patterns:

```
lib/
├── domain/
│   ├── models/
│   │   ├── inbox_item.dart        # Core domain model, type enum, validation, JSON serialization
│   │   └── filter_options.dart    # Filter, sort, and view mode models
├── data/
│   ├── services/
│   │   ├── storage_service.dart   # Abstract storage interface
│   │   └── shared_preferences_storage_service.dart # Local disk persistence implementation
│   └── repositories/
│       └── inbox_repository.dart  # Single source of truth, CRUD operations, query engine
├── ui/
│   ├── core/
│   │   ├── app_theme.dart         # Material 3 light & dark themes
│   │   └── utils.dart             # Date formatting, URL normalizer & launcher, clipboard helpers
│   ├── view_models/
│   │   └── inbox_view_model.dart  # ChangeNotifier managing UI state, filters, searches
│   └── features/
│       ├── inbox/
│       │   ├── views/inbox_screen.dart       # Main inbox list, search bar, sort & archive toggle
│       │   └── widgets/
│       │       ├── item_card.dart            # Visual card for notes, links, images
│       │       ├── tag_chip_list.dart        # Horizontal filter chips for tags
│       │       └── empty_inbox_view.dart     # Context-aware empty state widget
│       ├── create_edit/
│       │   └── views/create_edit_screen.dart # Creation & edit form with validations & live previews
│       └── item_detail/
│           └── views/item_detail_screen.dart # Full detail viewer with action buttons & pinch zoom
└── main.dart                      # App entry point, dependency injection with Provider
```

For an in-depth breakdown of how the architecture, data flow, and edge cases function, see [FUNCTIONING.md](FUNCTIONING.md).

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.19+ / Dart 3.3+)
- Android development environment (Android Studio/emulator or a physical Android device)
- Optional iOS development environment (macOS with Xcode and CocoaPods)

### Installation

1. **Clone or Navigate to the project directory**:
   ```bash
   cd "Byte Task"
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the Android app**:
   ```bash
   flutter run -d emulator-5554
   ```

This project targets Android. The `linux`, `macos`, `windows`, and `web` folders are retained as Flutter-generated scaffolding and are not supported app targets.

### Optional iOS setup

To run on iOS, add `GoogleService-Info.plist` from the same Firebase project to the `ios/Runner` target in Xcode, then run `flutter run -d ios` on macOS. iOS builds cannot be produced on Windows.

---

## 🧪 Running Tests

The project includes unit tests for domain models and repositories, persistence simulation tests, view-model state tests, and widget tests:

```bash
# Run all tests
flutter test

# Run static analysis
dart analyze
```

### Test Coverage Highlights:
- **`inbox_item_test.dart`**: Validates UUID generation, tag sanitization, fallback auto-titling for all 3 item types, serialization/deserialization, and `copyWith`.
- **`inbox_repository_test.dart`**: Validates CRUD operations, archiving/restoring, multi-field search, type & tag filtering, custom sorting, and **app relaunch simulation** (ensuring all data survives termination and reinitialization).
- **`inbox_view_model_test.dart`**: Tests reactive state updates, listener notifications, and filter resets.
- **`widget_test.dart`**: Validates UI rendering, search query filtering, archive switching, and creating a new note via the `CreateEditScreen`.

---

## 📦 Dependencies

- [`provider`](https://pub.dev/packages/provider): Pragmatic state management following MVVM.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): Multiplatform local key-value persistence.
- [`uuid`](https://pub.dev/packages/uuid): RFC4122 v4 unique identifier generation.
- [`intl`](https://pub.dev/packages/intl): Human-readable date and time formatting.
- [`url_launcher`](https://pub.dev/packages/url_launcher): Cross-platform URL browser launching.
- [`file_picker`](https://pub.dev/packages/file_picker): Native file explorer integration for selecting local image files.

## Firebase setup

The Android app uses Firebase Authentication (email/password) and Cloud Firestore. Firebase is configured from `android/app/google-services.json`; this file contains project identifiers and an API key, not server credentials. Security comes from Authentication and the Firestore rules.

1. Create a Firebase project in the Firebase Console.
2. Enable Authentication → Sign-in method → Email/Password.
3. Create a Firestore database.
4. Install the Firebase CLI, run `firebase login`, then from this project directory run `firebase use --add` and `firebase deploy --only firestore:rules`.
5. Run the app normally on Android:

```powershell
flutter run -d emulator-5554
```

The app accepts an email or username. Usernames are converted to an internal Firebase email address, while Firestore documents are scoped by the authenticated Firebase UID. [firestore.rules](./firestore.rules) enforces ownership on reads, creates, updates, and deletes, including direct document-ID requests. Dart-defines are still supported for non-Android or CI builds without native Firebase configuration.

The sign-in screen is implemented in `lib/ui/features/auth/views/auth_screen.dart`, and Firebase calls are in `lib/data/services/auth_service.dart`. If sign-up or sign-in shows `operation-not-allowed`, enable Email/Password in Firebase Console and rebuild. The emulator also needs internet access for Firebase authentication.
