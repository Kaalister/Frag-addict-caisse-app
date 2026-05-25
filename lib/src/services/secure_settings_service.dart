part of '../../main.dart';

class SecureSettingsService {
  static const _helloAssoSecretPrefix = 'helloasso_client_secret';
  static const _storage = FlutterSecureStorage();

  String get _helloAssoSecretKey =>
      '${_helloAssoSecretPrefix}_${FirebaseAuth.instance.currentUser?.uid ?? 'local'}';

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
