// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXwY2nPGWQmDpdsN9mGMy0eVO4-SFAV4Y',
    appId: '1:553688880808:web:5468b64d313905c6a0949d',
    messagingSenderId: '553688880808',
    projectId: 'walk-3c0ee',
    authDomain: 'walk-3c0ee.firebaseapp.com',
    storageBucket: 'walk-3c0ee.firebasestorage.app',
    measurementId: 'G-NSNCDVVT8W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjLMXiAKMEdfysyRltY1r_4d7hKR6IVeI',
    appId: '1:553688880808:android:9eede7c8236b112aa0949d',
    messagingSenderId: '553688880808',
    projectId: 'walk-3c0ee',
    storageBucket: 'walk-3c0ee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTnGUfx6TRz_VKVxVnm5nzN_NcqV5mh70',
    appId: '1:553688880808:ios:dd765d8616e1fbbba0949d',
    messagingSenderId: '553688880808',
    projectId: 'walk-3c0ee',
    storageBucket: 'walk-3c0ee.firebasestorage.app',
    iosBundleId: 'com.example.walkGuardian',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDTnGUfx6TRz_VKVxVnm5nzN_NcqV5mh70',
    appId: '1:553688880808:ios:dd765d8616e1fbbba0949d',
    messagingSenderId: '553688880808',
    projectId: 'walk-3c0ee',
    storageBucket: 'walk-3c0ee.firebasestorage.app',
    iosBundleId: 'com.example.walkGuardian',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCXwY2nPGWQmDpdsN9mGMy0eVO4-SFAV4Y',
    appId: '1:553688880808:web:3109c529a8603bb3a0949d',
    messagingSenderId: '553688880808',
    projectId: 'walk-3c0ee',
    authDomain: 'walk-3c0ee.firebaseapp.com',
    storageBucket: 'walk-3c0ee.firebasestorage.app',
    measurementId: 'G-MLK17TH1DM',
  );
}
