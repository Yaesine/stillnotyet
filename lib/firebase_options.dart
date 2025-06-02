import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyBGdg9dDBOa-THR7iPZEJCbKi8THsBEzH8',
    appId: '1:395654341992:web:dfc948e294f65f518022dd',
    messagingSenderId: '395654341992',
    projectId: 'marifecto',
    authDomain: 'marifecto.firebaseapp.com',
    storageBucket: 'marifecto.firebasestorage.app',
    measurementId: 'G-38FX86PFGK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6IzPDIXLGmRFIWa_qtnUVeBBithbkq2A',
    appId: '1:395654341992:android:2efd2ee1443bde5a8022dd',
    messagingSenderId: '395654341992',
    projectId: 'marifecto',
    storageBucket: 'marifecto.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC9uen8hB47r0X0gkyfIXgfMmjvGSSOTwM',
    appId: '1:395654341992:ios:9cf166dfe7ee0df08022dd',
    messagingSenderId: '395654341992',
    projectId: 'marifecto',
    storageBucket: 'marifecto.firebasestorage.app',
    iosClientId: '395654341992-6pc2h2pmpou2fg59q5lpbv1g1lp6f7gv.apps.googleusercontent.com',
    iosBundleId: 'com.marifecto.datechatmeet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC9uen8hB47r0X0gkyfIXgfMmjvGSSOTwM',
    appId: '1:395654341992:ios:282de64a05d130f28022dd',
    messagingSenderId: '395654341992',
    projectId: 'marifecto',
    storageBucket: 'marifecto.firebasestorage.app',
    iosClientId: '395654341992-40e3uqm4f1u340v9j4ptk4d50er18o7t.apps.googleusercontent.com',
    iosBundleId: 'com.example.newTinderClone',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBGdg9dDBOa-THR7iPZEJCbKi8THsBEzH8',
    appId: '1:395654341992:web:c0afc25917791ac48022dd',
    messagingSenderId: '395654341992',
    projectId: 'marifecto',
    authDomain: 'marifecto.firebaseapp.com',
    storageBucket: 'marifecto.firebasestorage.app',
    measurementId: 'G-S55JRCYMNX',
  );

}