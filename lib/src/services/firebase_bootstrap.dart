import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:tilly/src/domain/models.dart';

class FirebaseBootstrap {
  static const _syncAppName = 'tilly_sync';

  static bool initialized = false;
  static String? error;
  static FirebaseSettings? settings;
  static FirebaseApp? _syncApp;

  static FirebaseAuth get auth {
    final app = _syncApp;
    if (!initialized || app == null) {
      throw StateError(error ?? 'Firebase non configuré');
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  static FirebaseFirestore get firestore {
    final app = _syncApp;
    if (!initialized || app == null) {
      throw StateError(error ?? 'Firebase non configuré');
    }
    return FirebaseFirestore.instanceFor(app: app);
  }

  static User? get currentUser {
    if (!initialized) return null;
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize(FirebaseSettings? configuredSettings) async {
    initialized = false;
    settings = configuredSettings;
    if (configuredSettings == null || !configuredSettings.isConfigured) {
      error = 'Configuration Firebase à compléter';
      return;
    }
    try {
      await _findSyncApp()?.delete();
      _syncApp = await Firebase.initializeApp(
        name: _syncAppName,
        options: configuredSettings.toOptions(),
      );
      initialized = true;
      error = null;
    } catch (exception) {
      error = '$exception';
    }
  }

  static Future<void> reconfigure(FirebaseSettings configuredSettings) async {
    await _deleteCurrentApp();
    await initialize(configuredSettings);
  }

  static Future<void> reset() async {
    await _deleteCurrentApp();
    initialized = false;
    settings = null;
    error = 'Firebase non configuré';
  }

  static Future<void> _deleteCurrentApp() async {
    if (initialized) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    final app = _syncApp ?? _findSyncApp();
    try {
      await app?.delete();
    } catch (_) {}
    _syncApp = null;
    initialized = false;
  }

  static FirebaseApp? _findSyncApp() {
    for (final app in Firebase.apps) {
      if (app.name == _syncAppName) return app;
    }
    return null;
  }
}
