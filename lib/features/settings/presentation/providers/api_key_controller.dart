import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/network/api_key_service.dart';

final apiKeyControllerProvider =
    AsyncNotifierProvider<ApiKeyController, String?>(ApiKeyController.new);

class ApiKeyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    if (!sl.isRegistered<ApiKeyService>()) {
      return null;
    }
    return sl<ApiKeyService>().getUserKey();
  }

  /// Saves [key] to secure storage.  Pass an empty string to clear the key
  /// and fall back to the .env value.
  Future<void> saveKey(String key) async {
    if (!sl.isRegistered<ApiKeyService>()) {
      state = const AsyncData(null);
      return;
    }

    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await sl<ApiKeyService>().clearUserKey();
      state = const AsyncData(null);
    } else {
      await sl<ApiKeyService>().saveUserKey(trimmed);
      state = AsyncData(trimmed);
    }
  }
}
