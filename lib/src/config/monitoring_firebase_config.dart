import 'package:flutter/foundation.dart';

class MonitoringFirebaseConfig {
  const MonitoringFirebaseConfig._();

  static const enabled = bool.fromEnvironment(
    'TILLY_MONITORING_ENABLED',
    defaultValue: true,
  );
  static const collectInDebug = bool.fromEnvironment(
    'TILLY_MONITORING_DEBUG',
    defaultValue: false,
  );

  static bool get shouldCollect => enabled && (kReleaseMode || collectInDebug);
}
