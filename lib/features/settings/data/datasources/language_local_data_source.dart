import '../../domain/entities/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LanguageLocalDataSource {
  Future<AppLanguage> getLanguage();
  Future<AppLanguage> setLanguage(AppLanguage language);
}

class LanguageLocalDataSourceImpl implements LanguageLocalDataSource {
  const LanguageLocalDataSourceImpl(this._preferences);

  static const String _languageKey = 'app_language_code';

  final SharedPreferences _preferences;

  @override
  Future<AppLanguage> getLanguage() async {
    final current = _preferences.getString(_languageKey);
    for (final language in AppLanguage.values) {
      if (language.code == current) {
        return language;
      }
    }

    return AppLanguage.thai;
  }

  @override
  Future<AppLanguage> setLanguage(AppLanguage language) async {
    await _preferences.setString(_languageKey, language.code);
    return language;
  }
}
