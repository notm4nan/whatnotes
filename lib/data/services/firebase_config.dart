import 'package:firebase_core/firebase_core.dart';

/// Android uses android/app/google-services.json. Dart defines remain available
/// for web, desktop, or CI builds that do not have native Firebase config.
class FirebaseConfig {
  FirebaseConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool get hasDartDefines =>
      apiKey.isNotEmpty && appId.isNotEmpty && messagingSenderId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      );
}
