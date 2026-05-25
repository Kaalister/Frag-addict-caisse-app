part of '../../main.dart';

class FirebaseBootstrap {
  static bool initialized = false;
  static String? error;

  static Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (_isPlaceholder(options)) {
        error = 'Configuration Firebase à compléter';
        return;
      }
      await Firebase.initializeApp(options: options);
      initialized = true;
    } catch (exception) {
      error = '$exception';
    }
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.apiKey.contains('REPLACE_ME') ||
        options.appId.contains('REPLACE_ME') ||
        options.projectId.contains('REPLACE_ME');
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
  static const name = 'Frags Addicts Tactical POS';
  static const mood = 'noir carbone, vert traceur, cyan instrumentation';
  static const radius = 8.0;
}

const _dataEnvironmentSuffix = kReleaseMode ? '' : '_dev';
const _firebaseSnapshotId = kReleaseMode ? 'caisse-main' : 'caisse-dev';
const _githubOwner = 'Kaalister';
const _githubRepo = 'Frag-addict-caisse-app';
const _appBuildVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const _latestReleaseApi =
    'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

String _databaseFileName(String? userScopeId) {
  if (userScopeId == null) {
    return 'frags_addicts_caisse$_dataEnvironmentSuffix.db';
  }
  return 'frags_addicts_caisse${_dataEnvironmentSuffix}_$userScopeId.db';
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
          'User-Agent': 'FragsAddictsCaisseUpdateChecker',
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

class CaisseAirsoftApp extends StatelessWidget {
  const CaisseAirsoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caisse Airsoft',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.accent,
          primary: AppColors.accent,
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
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.accent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return const IconThemeData(color: AppColors.muted);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12);
            }
            return const TextStyle(color: AppColors.muted, fontSize: 12);
          }),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          indicatorColor: AppColors.accent,
          selectedIconTheme: IconThemeData(color: Colors.black),
          unselectedIconTheme: IconThemeData(color: AppColors.muted),
          selectedLabelTextStyle:
              TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
          unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
        ),
      ),
      home: const RootShell(),
    );
  }
}
