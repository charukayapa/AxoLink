import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase configuration for AxoLink project (axolink-2f655)
/// Platform-aware initialization
class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDM28-ZWMom0yIStlSqFXCFHmvDmjHtG5M",
          authDomain: "axolink-2f655.firebaseapp.com",
          databaseURL: "https://axolink-2f655-default-rtdb.firebaseio.com",
          projectId: "axolink-2f655",
          storageBucket: "axolink-2f655.firebasestorage.app",
          messagingSenderId: "935006171646",
          appId: "1:935006171646:web:dbd4148c425ae3777890af",
          measurementId: "G-2PQ6P0HCQZ",
        ),
      );
    } catch (e) {
      if (e is FirebaseException && e.code == 'duplicate-app') {
        // App already initialized
      } else {
        rethrow;
      }
    }
  }
}
