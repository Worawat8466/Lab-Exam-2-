import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the LLM API key with a BYOK (Bring Your Own Key) hybrid strategy:
/// 1. User-supplied key stored in flutter_secure_storage (takes precedence)
/// 2. Fallback: GEMINI_API_KEY from .env file
class ApiKeyService {
  const ApiKeyService(this._storage);

  static const String _userKeyStorageKey = 'user_gemini_api_key';

  final FlutterSecureStorage _storage;

  /// Returns the user-stored key if available; otherwise falls back to .env.
  Future<String> getEffectiveKey() async {
    final userKey = await _storage.read(key: _userKeyStorageKey);
    if (userKey != null && userKey.isNotEmpty) {
      return userKey;
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Returns only the user-supplied key (null if not set).
  Future<String?> getUserKey() async {
    return _storage.read(key: _userKeyStorageKey);
  }

  /// Saves a user-supplied API key to secure storage.
  Future<void> saveUserKey(String key) async {
    await _storage.write(key: _userKeyStorageKey, value: key);
  }

  /// Clears the user-supplied key, making the app fall back to .env.
  Future<void> clearUserKey() async {
    await _storage.delete(key: _userKeyStorageKey);
  }
}
