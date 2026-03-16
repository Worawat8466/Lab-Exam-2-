import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/app_language.dart';
import '../providers/api_key_controller.dart';
import '../providers/app_language_controller.dart';
import '../providers/theme_mode_controller.dart';

@RoutePage()
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(apiKeyControllerProvider).value;
      if (current != null && current.isNotEmpty) {
        _keyController.text = current;
      }
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    await ref
        .read(apiKeyControllerProvider.notifier)
        .saveKey(_keyController.text);
    if (!mounted) {
      return;
    }
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _keyController.text.trim().isEmpty
              ? AppStrings.of(
                  ref.read(appLanguageControllerProvider).value ??
                      AppLanguage.thai,
                ).apiKeyCleared
              : AppStrings.of(
                  ref.read(appLanguageControllerProvider).value ??
                      AppLanguage.thai,
                ).apiKeySaved,
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _saved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeModeControllerProvider);
    final isDark = themeAsync.value == ThemeMode.dark;
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final language = languageAsync.value ?? AppLanguage.thai;
    final strings = AppStrings.of(language);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            value: isDark,
            title: Text(strings.darkMode),
            subtitle: Text(strings.darkModeSubtitle),
            onChanged: (_) async {
              await ref.read(themeModeControllerProvider.notifier).toggle();
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(strings.language),
            subtitle: const Text('ไทย / English'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(value: AppLanguage.thai, label: Text('ไทย')),
                ButtonSegment(
                  value: AppLanguage.english,
                  label: Text('English'),
                ),
              ],
              selected: {language},
              onSelectionChanged: (selection) async {
                await ref
                    .read(appLanguageControllerProvider.notifier)
                    .setLanguage(selection.first);
              },
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(strings.manageCategories),
            subtitle: Text(strings.manageCategoriesSubtitle),
            onTap: () async {
              await context.router.push(const ExpenseMetadataRoute());
            },
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.apiKeyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.apiKeySubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: strings.apiKeyHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _obscureKey
                            ? 'แสดง API Key'
                            : 'ซ่อน API Key',
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.apiKeyTitle,
                          onPressed: _saveKey,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _saved
                                ? const Icon(
                                    Icons.check_circle,
                                    key: ValueKey('saved'),
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                    key: ValueKey('save'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
