part of '../../main.dart';

class FirebaseBootstrap {
  static bool initialized = false;
  static String? error;
  static FirebaseSettings? settings;

  static User? get currentUser {
    if (!initialized) return null;
    try {
      return FirebaseAuth.instance.currentUser;
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
      await Firebase.initializeApp(options: configuredSettings.toOptions());
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
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    if (Firebase.apps.isNotEmpty) {
      try {
        await Firebase.app().delete();
      } catch (_) {}
    }
    initialized = false;
  }
}

class AppColors {
  static const bg = Color(0xFF0D0D0D);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF1E1E1E);
  static const border = Color(0xFF2A2A2A);
  static const accent = Color(0xFFC8F135);
  static const accent2 = Color(0xFF35C8F1);
  static const danger = Color(0xFFF13535);
  static const warn = Color(0xFFF1A035);
  static const text = Color(0xFFF0F0F0);
  static const muted = Color(0xFF8B8B8B);
  static const cash = Color(0xFF4CAF50);
  static const paypal = Color(0xFF1565C0);
  static const sumup = Color(0xFF7B1FA2);
}

class VisualIdentity {
  static const name = 'Tilly';
  static const mood = 'noir carbone, vert traceur, cyan instrumentation';
  static const radius = 8.0;
}

extension ThemeAccent on BuildContext {
  Color get primaryAccent => Theme.of(this).colorScheme.primary;
  Color get onPrimaryAccent => Theme.of(this).colorScheme.onPrimary;
}

const _dataEnvironmentSuffix = kReleaseMode ? '' : '_dev';
const _firebaseOrganizationId = 'default';
const _firebaseSnapshotId = kReleaseMode ? 'caisse-main' : 'caisse-dev';
const _githubOwner = 'Kaalister';
const _githubRepo = 'Tilly-caisse-app';
const _appBuildVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const _latestReleaseApi =
    'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
const _firebaseSetupGuideUrl =
    'https://github.com/$_githubOwner/$_githubRepo/blob/main/documentation/FIREBASE_SETUP.md';
const _helloAssoSetupGuideUrl =
    'https://github.com/$_githubOwner/$_githubRepo/blob/main/documentation/MISE_EN_PLACE.md#12-configurer-helloasso';

String _databaseFileName(String? userScopeId) {
  if (userScopeId == null) {
    return 'tilly$_dataEnvironmentSuffix.db';
  }
  return 'tilly${_dataEnvironmentSuffix}_$userScopeId.db';
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.assetName,
    required this.publishedAt,
  });

  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseUrl;
  final String assetName;
  final DateTime? publishedAt;
}

class AppUpdateResult {
  const AppUpdateResult({
    this.update,
    this.latestVersion,
    this.error,
  });

  final AppUpdateInfo? update;
  final String? latestVersion;
  final String? error;

  bool get requiresUpdate => update != null;
}

class AppUpdateService {
  static bool get supportedPlatform => Platform.isAndroid || Platform.isWindows;

  static Future<AppUpdateResult> check() async {
    if (!supportedPlatform) {
      return const AppUpdateResult(latestVersion: _appBuildVersion);
    }

    try {
      final response = await http.get(
        Uri.parse(_latestReleaseApi),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'TillyUpdateChecker',
        },
      );
      if (response.statusCode != 200) {
        return AppUpdateResult(
            error:
                'GitHub a répondu ${response.statusCode}. Vérification impossible.');
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return const AppUpdateResult(
            error: 'Réponse GitHub invalide. Vérification impossible.');
      }

      final tag = '${payload['tag_name'] ?? ''}'.trim();
      final latestVersion = _cleanVersion(tag);
      if (latestVersion.isEmpty) {
        return const AppUpdateResult(
            error: 'La dernière Release GitHub ne contient pas de tag valide.');
      }

      if (_compareVersions(latestVersion, _appBuildVersion) <= 0) {
        return AppUpdateResult(latestVersion: latestVersion);
      }

      final asset = _platformAsset(payload['assets']);
      final releaseUrl =
          '${payload['html_url'] ?? 'https://github.com/$_githubOwner/$_githubRepo/releases/latest'}';
      final downloadUrl =
          '${asset?['browser_download_url'] ?? releaseUrl}'.trim();
      final assetName = '${asset?['name'] ?? 'GitHub Release'}'.trim();
      final publishedAt = DateTime.tryParse('${payload['published_at'] ?? ''}');

      return AppUpdateResult(
        latestVersion: latestVersion,
        update: AppUpdateInfo(
          latestVersion: latestVersion,
          currentVersion: _appBuildVersion,
          downloadUrl: downloadUrl,
          releaseUrl: releaseUrl,
          assetName: assetName.isEmpty ? 'GitHub Release' : assetName,
          publishedAt: publishedAt,
        ),
      );
    } catch (error) {
      return AppUpdateResult(error: 'Vérification impossible : $error');
    }
  }

  static Map<String, dynamic>? _platformAsset(dynamic assets) {
    if (assets is! List) return null;
    final typedAssets =
        assets.whereType<Map>().map((asset) => asset.cast<String, dynamic>());
    bool matches(Map<String, dynamic> asset, String extension) {
      final name = '${asset['name'] ?? ''}'.toLowerCase();
      return name.endsWith(extension);
    }

    if (Platform.isAndroid) {
      return typedAssets.where((asset) => matches(asset, '.apk')).firstOrNull;
    }
    if (Platform.isWindows) {
      return typedAssets.where((asset) {
            final name = '${asset['name'] ?? ''}'.toLowerCase();
            return name.endsWith('.exe') && name.contains('setup');
          }).firstOrNull ??
          typedAssets.where((asset) => matches(asset, '.exe')).firstOrNull ??
          typedAssets.where((asset) => matches(asset, '.zip')).firstOrNull;
    }
    return null;
  }
}

String _cleanVersion(String value) {
  return value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
}

int _compareVersions(String a, String b) {
  final left = _versionParts(a);
  final right = _versionParts(b);
  final length = max(left.length, right.length);
  for (var index = 0; index < length; index++) {
    final leftPart = index < left.length ? left[index] : 0;
    final rightPart = index < right.length ? right[index] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }
  return 0;
}

List<int> _versionParts(String version) {
  return _cleanVersion(version)
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

class TillyApp extends StatelessWidget {
  const TillyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tilly',
      theme: caisseTheme(AppColors.accent),
      home: const RootShell(),
    );
  }
}

ThemeData caisseTheme(Color primaryColor) {
  final onPrimary = _readableOnColor(primaryColor);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: onPrimary,
      secondary: AppColors.accent2,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualIdentity.radius),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: primaryColor),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: onPrimary);
        }
        return const IconThemeData(color: AppColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
              color: primaryColor, fontWeight: FontWeight.w800, fontSize: 12);
        }
        return const TextStyle(color: AppColors.muted, fontSize: 12);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: primaryColor,
      selectedIconTheme: IconThemeData(color: onPrimary),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle:
          TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.muted),
    ),
  );
}

Color _readableOnColor(Color color) =>
    color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
