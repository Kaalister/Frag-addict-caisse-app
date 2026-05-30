import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'firebase_options.dart';

part 'src/app/app.dart';
part 'src/controllers/app_controller.dart';
part 'src/data/local_database.dart';
part 'src/domain/models.dart';
part 'src/exports/pdf_exports.dart';
part 'src/platform/backup_and_links.dart';
part 'src/services/firebase_sync_service.dart';
part 'src/services/hello_asso_client.dart';
part 'src/services/hello_asso_import_service.dart';
part 'src/services/meal_service.dart';
part 'src/services/secure_settings_service.dart';
part 'src/services/stock_service.dart';
part 'src/ui/dialogs.dart';
part 'src/ui/pages/bilan_page.dart';
part 'src/ui/pages/cash_analysis_page.dart';
part 'src/ui/pages/configuration_page.dart';
part 'src/ui/pages/kpi_page.dart';
part 'src/ui/pages/meals_page.dart';
part 'src/ui/pages/players_page.dart';
part 'src/ui/pages/sales_page.dart';
part 'src/ui/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqflite_ffi.sqfliteFfiInit();
    databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }
  await FirebaseBootstrap.initialize();
  runApp(const CaisseAirsoftApp());
}
