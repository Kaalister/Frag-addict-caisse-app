import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/monitoring_firebase_config.dart';

class FirebaseMonitoringService {
  const FirebaseMonitoringService._();

  static bool initialized = false;
  static String? error;

  static Future<void> initialize() async {
    initialized = false;
    error = null;

    if (!MonitoringFirebaseConfig.enabled) return;
    if (!Platform.isAndroid) {
      error = 'Firebase monitoring actif uniquement sur Android';
      return;
    }

    try {
      await _initializeDefaultApp();
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        MonitoringFirebaseConfig.shouldCollect,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        MonitoringFirebaseConfig.shouldCollect,
      );
      initialized = true;

      if (!MonitoringFirebaseConfig.shouldCollect) return;
      _installCrashHandlers();
      await FirebaseAnalytics.instance.logAppOpen();
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'build_mode',
        value: kReleaseMode ? 'release' : 'debug',
      );
    } catch (exception) {
      error = '$exception';
      debugPrint('Firebase monitoring disabled: $exception');
    }
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!initialized || !MonitoringFirebaseConfig.shouldCollect) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {}
  }

  static void logAction(
    String action, {
    Map<String, Object?> context = const {},
  }) {
    if (!initialized || !MonitoringFirebaseConfig.shouldCollect) return;
    final safeAction = _safeValue(action);
    final details = context.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${_safeKey(entry.key)}=${_safeValue(entry.value!)}')
        .join(' ');
    final message = details.isEmpty ? safeAction : '$safeAction $details';

    try {
      unawaited(FirebaseCrashlytics.instance.log(message));
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey('last_action', safeAction),
      );
    } catch (_) {}
  }

  static void setContextKey(String key, Object value) {
    if (!initialized || !MonitoringFirebaseConfig.shouldCollect) return;
    try {
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey(
          _safeKey(key),
          _safeValue(value),
        ),
      );
    } catch (_) {}
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    if (!initialized || !MonitoringFirebaseConfig.shouldCollect) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
      );
    } catch (_) {}
  }

  static Future<void> _initializeDefaultApp() async {
    try {
      Firebase.app();
      return;
    } catch (_) {
      await Firebase.initializeApp();
    }
  }

  static void _installCrashHandlers() {
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previousFlutterError != null) {
        previousFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static String _safeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _safeValue(Object value) {
    final text = '$value'.replaceAll(RegExp(r'\s+'), '_').trim();
    if (text.length <= 80) return text;
    return text.substring(0, 80);
  }
}
