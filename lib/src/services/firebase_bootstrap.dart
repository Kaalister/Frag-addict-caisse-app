import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:tilly/src/domain/models.dart';

class FirebaseBootstrap {
  static const _syncAppName = 'tilly_sync';

  static bool initialized = false;
  static String? error;
  static FirebaseSettings? settings;
  static FirebaseApp? _syncApp;
  static Future<void> _pendingOperation = Future<void>.value();

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

  static Future<void> initialize(FirebaseSettings? configuredSettings) =>
      _serialize(() => _activate(configuredSettings));

  static Future<void> reconfigure(FirebaseSettings configuredSettings) =>
      _serialize(() async {
        await _signOutCurrentUser();
        _syncApp = null;
        initialized = false;
        await _activate(configuredSettings);
      });

  static Future<void> reset() => _serialize(() async {
        await _signOutCurrentUser();
        _syncApp = null;
        initialized = false;
        settings = null;
        error = 'Firebase non configuré';
      });

  static Future<void> _activate(FirebaseSettings? configuredSettings) async {
    settings = configuredSettings;
    if (configuredSettings == null || !configuredSettings.isConfigured) {
      _syncApp = null;
      initialized = false;
      error = 'Configuration Firebase à compléter';
      return;
    }

    try {
      final options = configuredSettings.toOptions();
      // Android Firebase components can outlive FirebaseApp.delete(). Reuse a
      // compatible app or choose a fresh name to avoid reopening its DataStore.
      _syncApp = _findCompatibleSyncApp(options) ??
          await Firebase.initializeApp(
            name: _nextSyncAppName(),
            options: options,
          );
      initialized = true;
      error = null;
    } catch (exception) {
      _syncApp = null;
      initialized = false;
      error = '$exception';
    }
  }

  static Future<void> _signOutCurrentUser() async {
    if (initialized) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  static FirebaseApp? _findCompatibleSyncApp(FirebaseOptions options) {
    for (final app in Firebase.apps) {
      if (app.name.startsWith(_syncAppName) &&
          _sameOptions(app.options, options)) {
        return app;
      }
    }
    return null;
  }

  static bool _sameOptions(FirebaseOptions left, FirebaseOptions right) =>
      left.apiKey == right.apiKey &&
      left.appId == right.appId &&
      left.messagingSenderId == right.messagingSenderId &&
      left.projectId == right.projectId &&
      left.authDomain == right.authDomain &&
      left.storageBucket == right.storageBucket &&
      left.measurementId == right.measurementId;

  static String _nextSyncAppName() {
    final names = Firebase.apps.map((app) => app.name).toSet();
    if (!names.contains(_syncAppName)) return _syncAppName;

    var suffix = 2;
    while (names.contains('${_syncAppName}_$suffix')) {
      suffix += 1;
    }
    return '${_syncAppName}_$suffix';
  }

  static Future<void> _serialize(Future<void> Function() operation) {
    final next = _pendingOperation.then((_) => operation());
    _pendingOperation = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }
}
