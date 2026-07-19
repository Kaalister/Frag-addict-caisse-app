import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/iterable_extensions.dart';

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
  static const _requestTimeout = Duration(seconds: 15);

  static bool get supportedPlatform => Platform.isAndroid || Platform.isWindows;

  static Future<AppUpdateResult> check() async {
    if (!supportedPlatform) {
      return const AppUpdateResult(latestVersion: appBuildVersion);
    }

    try {
      final response = await http.get(
        Uri.parse(latestReleaseApi),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'TillyUpdateChecker',
        },
      ).timeout(_requestTimeout);
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

      if (_compareVersions(latestVersion, appBuildVersion) <= 0) {
        return AppUpdateResult(latestVersion: latestVersion);
      }

      final asset = _platformAsset(payload['assets']);
      final releaseUrl =
          '${payload['html_url'] ?? 'https://github.com/$githubOwner/$githubRepo/releases/latest'}';
      final downloadUrl =
          '${asset?['browser_download_url'] ?? releaseUrl}'.trim();
      final assetName = '${asset?['name'] ?? 'GitHub Release'}'.trim();
      final publishedAt = DateTime.tryParse('${payload['published_at'] ?? ''}');

      return AppUpdateResult(
        latestVersion: latestVersion,
        update: AppUpdateInfo(
          latestVersion: latestVersion,
          currentVersion: appBuildVersion,
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
