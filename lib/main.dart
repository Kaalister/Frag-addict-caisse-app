import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'src/app/app.dart';
import 'src/services/firebase_bootstrap.dart';
import 'src/services/firebase_monitoring_service.dart';
import 'src/services/secure_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPhoneToPortrait();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqflite_ffi.sqfliteFfiInit();
    databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }
  await FirebaseMonitoringService.initialize();
  final firebaseSettings = await SecureSettingsService().loadFirebaseSettings();
  await FirebaseBootstrap.initialize(firebaseSettings);
  runApp(const TillyApp());
}

Future<void> _lockPhoneToPortrait() async {
  if (!Platform.isAndroid) return;

  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide < 600) {
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }
}
