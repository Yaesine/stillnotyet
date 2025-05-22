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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'YOUR-WEB-API-KEY',
    appId: 'YOUR-WEB-APP-ID',
    messagingSenderId: '1075080846660',
    projectId: 'tinderclones-4f4c4',
    authDomain: 'tinderclones-4f4c4.firebaseapp.com',
    storageBucket: 'tinderclones-4f4c4.appspot.com',
    databaseURL: 'https://tinderclones-4f4c4-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOk-PEqieOaJ5O7RXEI8_lfBMQw5KJksI',
    appId: '1075080846660-q2bseqsgi407q7lo1pa3jomtsssrsf0i.apps.googleusercontent.com',
    messagingSenderId: '1075080846660',
    projectId: 'tinderclones-4f4c4',
    storageBucket: 'tinderclones-4f4c4.appspot.com',
    databaseURL: 'https://tinderclones-4f4c4-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOk-PEqieOaJ5O7RXEI8_lfBMQw5KJksI',
    appId: '1:1075080846660:ios:613de45ee4399153d70b11',
    messagingSenderId: '1075080846660',
    projectId: 'tinderclones-4f4c4',
    storageBucket: 'tinderclones-4f4c4.appspot.com',
    databaseURL: 'https://tinderclones-4f4c4-default-rtdb.firebaseio.com',
    iosClientId: '1075080846660-fehqn2upmf9ktd5v2or4g987ecqu3rej.apps.googleusercontent.com',
    iosBundleId: 'com.ycheqrouni.newtinderclone',
  );
}