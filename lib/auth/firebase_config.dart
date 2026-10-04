import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Public client identifiers only. Never put service-account keys here.
class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static bool get hasOverrides => [
    apiKey,
    appId,
    projectId,
    senderId,
    authDomain,
    iosBundleId,
  ].any((s) => s.isNotEmpty);
  static bool get configured {
    if (hasOverrides) {
      return [apiKey, appId, projectId, senderId].every((s) => s.isNotEmpty);
    }
    try {
      DefaultFirebaseOptions.currentPlatform;
      return true;
    } on UnsupportedError {
      return false;
    }
  }

  static FirebaseOptions get options => hasOverrides
      ? FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          projectId: projectId,
          messagingSenderId: senderId,
          authDomain: authDomain.isEmpty
              ? '$projectId.firebaseapp.com'
              : authDomain,
          iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
        )
      : DefaultFirebaseOptions.currentPlatform;
}
