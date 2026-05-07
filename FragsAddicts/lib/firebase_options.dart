import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
          'Firebase Web n’est pas configuré pour cette app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
            'Firebase n’est configuré que pour Android et Windows.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeAdS2UzeBtmTskqFen5w3hdOQI07D0OM',
    appId: '1:418329101136:android:ccdeb4fbb93707bfb36255',
    messagingSenderId: '418329101136',
    projectId: 'frag-addict-caisse',
    storageBucket: 'frag-addict-caisse.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDzmu1FKB3Y99n24YN24DWjSpm5h262-aU',
    appId: '1:418329101136:web:98a7ded562a392fab36255',
    messagingSenderId: '418329101136',
    projectId: 'frag-addict-caisse',
    authDomain: 'frag-addict-caisse.firebaseapp.com',
    storageBucket: 'frag-addict-caisse.firebasestorage.app',
    measurementId: 'G-11744X53D0',
  );
}
