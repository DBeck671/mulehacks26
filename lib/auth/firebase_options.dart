import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Public client identifiers for the free SideQuest Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase is configured for web, Android and iOS.',
      ),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDHYM-T981X0chNr7853BKsUO0fmrpQSok',
    appId: '1:174672682223:web:425ee5e2ca778bcb16cf1a',
    messagingSenderId: '174672682223',
    projectId: 'sidequest-7c7e0',
    authDomain: 'sidequest-7c7e0.firebaseapp.com',
    storageBucket: 'sidequest-7c7e0.firebasestorage.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBIHx58--PBfkjh6ep54bMiIi3PcfvxdvY',
    appId: '1:174672682223:android:f9fd00aa0e28e37b16cf1a',
    messagingSenderId: '174672682223',
    projectId: 'sidequest-7c7e0',
    storageBucket: 'sidequest-7c7e0.firebasestorage.app',
  );
  // Uses this project's browser client key with explicit Firebase options.
  // Replace with the auto-matched iOS key when running flutterfire configure.
  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDHYM-T981X0chNr7853BKsUO0fmrpQSok',
    appId: '1:174672682223:ios:7fb087e9cc7b24df16cf1a',
    messagingSenderId: '174672682223',
    projectId: 'sidequest-7c7e0',
    storageBucket: 'sidequest-7c7e0.firebasestorage.app',
    iosBundleId: 'com.sidequest.sidequest',
  );
}
