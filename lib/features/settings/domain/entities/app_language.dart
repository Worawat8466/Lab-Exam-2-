enum AppLanguage {
  thai(code: 'th', displayName: 'ไทย'),
  english(code: 'en', displayName: 'English');

  const AppLanguage({required this.code, required this.displayName});

  final String code;
  final String displayName;
}
