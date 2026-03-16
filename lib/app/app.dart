import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/entities/app_language.dart';
import '../features/settings/presentation/providers/app_language_controller.dart';
import '../features/settings/presentation/providers/theme_mode_controller.dart';
import 'di/service_locator.dart';
import 'router/app_router.dart';

class AiReceiptTrackerApp extends ConsumerWidget {
  const AiReceiptTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeControllerProvider);
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final appLanguage = languageAsync.value ?? AppLanguage.thai;
    final locale = appLanguage == AppLanguage.english
        ? const Locale('en', 'US')
        : const Locale('th', 'TH');

    const lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2E7D32), // Rich green
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFC8E6C9),
      onPrimaryContainer: Color(0xFF1B5E20),
      secondary: Color(0xFF1976D2), // Deep blue
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFBBDEFB),
      onSecondaryContainer: Color(0xFF0D47A1),
      tertiary: Color(0xFFF57C00), // Deep orange
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFCCBC),
      onTertiaryContainer: Color(0xFFE65100),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF8C0000),
      surface: Color(0xFFFDFDFD),
      onSurface: Color(0xFF1C1B1F),
      outline: Color(0xFF79747E),
    );

    const darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA5D6A7), // Light green
      onPrimary: Color(0xFF1B5E20),
      primaryContainer: Color(0xFF2E7D32),
      onPrimaryContainer: Color(0xFFC8E6C9),
      secondary: Color(0xFF90CAF9), // Light blue
      onSecondary: Color(0xFF0D47A1),
      secondaryContainer: Color(0xFF1976D2),
      onSecondaryContainer: Color(0xFFBBDEFB),
      tertiary: Color(0xFFFFB74D), // Light orange
      onTertiary: Color(0xFFE65100),
      tertiaryContainer: Color(0xFFF57C00),
      onTertiaryContainer: Color(0xFFFFCCBC),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C0000),
      onErrorContainer: Color(0xFFF9DEDC),
      surface: Color(0xFF171A1D),
      onSurface: Color(0xFFE6E1E6),
      outline: Color(0xFF938F99),
    );

    final lightTheme =
        ThemeData.from(
          colorScheme: lightColorScheme,
          useMaterial3: true,
        ).copyWith(
          scaffoldBackgroundColor: lightColorScheme.surface,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: lightColorScheme.surface,
            foregroundColor: lightColorScheme.onSurface,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: lightColorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: lightColorScheme.outline.withValues(alpha: 0.18),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: lightColorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: lightColorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: lightColorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: lightColorScheme.surface,
            indicatorColor: lightColorScheme.primaryContainer,
            elevation: 0,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: lightColorScheme.primary,
                );
              }
              return TextStyle(
                fontSize: 12,
                color: lightColorScheme.onSurface.withOpacity(0.6),
              );
            }),
          ),
        );

    final darkTheme =
        ThemeData.from(
          colorScheme: darkColorScheme,
          useMaterial3: true,
        ).copyWith(
          scaffoldBackgroundColor: darkColorScheme.surface,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: darkColorScheme.surface,
            foregroundColor: darkColorScheme.onSurface,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: darkColorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: darkColorScheme.outline.withValues(alpha: 0.22),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: darkColorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: darkColorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: darkColorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: darkColorScheme.surface,
            indicatorColor: darkColorScheme.primaryContainer,
            elevation: 0,
          ),
        );

    return MaterialApp.router(
      title: 'Smart Expense Auto-Tracker',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeModeAsync.value ?? ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: sl<AppRouter>().config(),
    );
  }
}
