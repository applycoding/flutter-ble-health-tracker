import 'package:firebase_core/firebase_core.dart';

/// Optional Firebase project values.
///
/// Leave the strings empty to run fully on-device. Replace them with the
/// output of `flutterfire configure` (or paste a real project here) to push
/// pending readings to Cloud Firestore collection `heart_rate_readings`.
abstract final class FirebaseProjectConfig {
  static const apiKey = '';
  static const appId = '';
  static const messagingSenderId = '';
  static const projectId = '';
  static const storageBucket = '';
  static const iosBundleId = 'com.pulsekeep.demo.pulsekeep';

  static const _placeholders = {
    '',
    'YOUR_API_KEY',
    'YOUR_APP_ID',
    'YOUR_PROJECT_ID',
    'YOUR_SENDER_ID',
  };

  static bool get isConfigured =>
      !_placeholders.contains(apiKey) &&
      !_placeholders.contains(appId) &&
      !_placeholders.contains(messagingSenderId) &&
      !_placeholders.contains(projectId);

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: iosBundleId,
  );
}
