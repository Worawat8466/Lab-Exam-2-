import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labexam2/features/settings/domain/entities/app_language.dart';
import 'package:labexam2/features/settings/presentation/pages/settings_page.dart';
import 'package:labexam2/features/settings/presentation/providers/app_language_controller.dart';
import 'package:labexam2/features/settings/presentation/providers/theme_mode_controller.dart';

class _FakeThemeModeController extends ThemeModeController {
  @override
  Future<ThemeMode> build() async => ThemeMode.light;

  @override
  Future<void> toggle() async {
    state = const AsyncData(ThemeMode.dark);
  }
}

class _FakeAppLanguageController extends AppLanguageController {
  @override
  Future<AppLanguage> build() async => AppLanguage.thai;

  @override
  Future<void> setLanguage(AppLanguage language) async {
    state = AsyncData(language);
  }
}

void main() {
  testWidgets('Settings page renders language controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeControllerProvider.overrideWith(
            _FakeThemeModeController.new,
          ),
          appLanguageControllerProvider.overrideWith(
            _FakeAppLanguageController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ภาษา'), findsOneWidget);
    expect(find.text('ไทย'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('จัดการหมวดหมู่และแท็ก'), findsOneWidget);
  });
}
