part of '../../main.dart';

class SecureSettingsService {
  static const _helloAssoSecretPrefix = 'helloasso_client_secret';
  static const _firebaseSettingsKey = 'firebase_settings';
  static const _storage = FlutterSecureStorage();

  String get _helloAssoSecretKey =>
      '${_helloAssoSecretPrefix}_${FirebaseBootstrap.currentUser?.uid ?? 'local'}';

  Future<FirebaseSettings?> loadFirebaseSettings() async {
    try {
      final value = await _storage.read(key: _firebaseSettingsKey);
      if (value == null || value.trim().isEmpty) return null;
      return FirebaseSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFirebaseSettings(FirebaseSettings settings) =>
      _storage.write(key: _firebaseSettingsKey, value: jsonEncode(settings));

  Future<void> clearFirebaseSettings() =>
      _storage.delete(key: _firebaseSettingsKey);

  Future<HelloAssoSettings> loadHelloAssoSettings(
      HelloAssoSettings storedSettings) async {
    final legacySecret = storedSettings.clientSecret.trim();
    if (legacySecret.isNotEmpty) {
      await _storage.write(key: _helloAssoSecretKey, value: legacySecret);
      return storedSettings;
    }
    final secret = await _storage.read(key: _helloAssoSecretKey) ?? '';
    return storedSettings.withSecret(secret);
  }

  Future<void> saveHelloAssoSecret(String value) async {
    final secret = value.trim();
    if (secret.isEmpty) {
      await _storage.delete(key: _helloAssoSecretKey);
    } else {
      await _storage.write(key: _helloAssoSecretKey, value: secret);
    }
  }
}
