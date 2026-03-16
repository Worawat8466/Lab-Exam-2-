import '../../features/settings/domain/entities/app_language.dart';

/// Simple bilingual string helper. Use with [AppLanguage] from the language
/// provider to get the correct string for Thai or English.
class AppStrings {
  const AppStrings._(this._lang);

  factory AppStrings.of(AppLanguage lang) => AppStrings._(lang);

  final AppLanguage _lang;
  bool get _isThai => _lang == AppLanguage.thai;

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome => _isThai ? 'หน้าแรก' : 'Home';
  String get navHistory => _isThai ? 'ประวัติ' : 'History';
  String get navSettings => _isThai ? 'ตั้งค่า' : 'Settings';

  // ── App / Home ──────────────────────────────────────────────────────────────
  String get appTitle => 'Smart Expense Auto-Tracker';
  String get totalSpend => _isThai ? 'ยอดใช้จ่าย' : 'Spending';
  String get totalIncome => _isThai ? 'รายรับ' : 'Income';
  String get totalExpense => _isThai ? 'รายจ่าย' : 'Expense';
  String get balance => _isThai ? 'ยอดคงเหลือ' : 'Balance';
  String get recentItems => _isThai ? 'รายการล่าสุด' : 'Recent Items';
  String get noItems => _isThai
      ? 'ยังไม่มีรายการ เริ่มด้วยการกด + ด้านล่าง'
      : 'No items yet. Tap + to get started';
  String get spendingByCategory =>
      _isThai ? 'สัดส่วนหมวดหมู่' : 'Category Breakdown';
  String get noCategory => _isThai ? 'ไม่มีข้อมูลหมวดหมู่' : 'No category data';
  String get topCategory => _isThai ? 'หมวดที่ใช้จ่ายมากสุด' : 'Top Category';
  String get manageCategoryTooltip =>
      _isThai ? 'จัดการหมวดหมู่และแท็ก' : 'Manage Categories & Tags';

  // ── FAB speed‑dial ─────────────────────────────────────────────────────────
  String get addManually => _isThai ? 'จด' : 'Log';
  String get scanReceipt => _isThai ? 'สแกนใบเสร็จ' : 'Scan Receipt';

  // ── Period chips ────────────────────────────────────────────────────────────
  String get weekly => _isThai ? 'สัปดาห์' : 'Weekly';
  String get monthly => _isThai ? 'เดือน' : 'Monthly';
  String get quarterly => _isThai ? 'ไตรมาส' : 'Quarterly';
  String get yearly => _isThai ? 'ปี' : 'Yearly';

  // ── History ────────────────────────────────────────────────────────────────
  String get historyTitle => _isThai ? 'ประวัติรายการ' : 'Transaction History';
  String get noHistory =>
      _isThai ? 'ยังไม่มีประวัติรายการ' : 'No transaction history';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsTitle => _isThai ? 'ตั้งค่า' : 'Settings';
  String get darkMode => _isThai ? 'โหมดมืด' : 'Dark Mode';
  String get darkModeSubtitle =>
      _isThai ? 'เปลี่ยนธีมแบบสมูท' : 'Toggle theme smoothly';
  String get language => _isThai ? 'ภาษา' : 'Language';
  String get manageCategories =>
      _isThai ? 'จัดการหมวดหมู่และแท็ก' : 'Manage Categories & Tags';
  String get manageCategoriesSubtitle => _isThai
      ? 'เพิ่ม แก้ไข ลบ สำหรับการจดและ AI'
      : 'Add, edit, delete for manual & AI entry';
  String get apiKeyTitle => 'LLM API Key (Gemini)';
  String get apiKeySubtitle => _isThai
      ? 'ว่างเปล่า = ใช้ค่าจาก .env อัตโนมัติ'
      : 'Empty = use .env value automatically';
  String get apiKeyHint =>
      _isThai ? 'วาง Gemini API Key ที่นี่' : 'Paste your Gemini API Key here';
  String get apiKeySaved =>
      _isThai ? 'บันทึก API Key แล้ว ✓' : 'API Key saved ✓';
  String get apiKeyCleared => _isThai
      ? 'ล้างค่า Key แล้ว ใช้ .env แทน'
      : 'Key cleared, using .env fallback';

  // ── Scan / AI ──────────────────────────────────────────────────────────────
  String get scanTitle => _isThai ? 'สแกน & AI รีวิว' : 'Scan & AI Review';
  String get loadGallery =>
      _isThai ? 'โหลดรูปใบเสร็จเดือนปัจจุบัน' : 'Load Receipts This Month';
  String get noImages =>
      _isThai ? 'ไม่พบรูปในเดือนปัจจุบัน' : 'No images found this month';
  String get aiProcessing =>
      _isThai ? 'กำลังแกะรอยใบเสร็จ...' : 'Analyzing receipt...';
  String get confirmAndSave => _isThai ? 'ยืนยันและบันทึก' : 'Confirm & Save';
  String get runAiParse =>
      _isThai ? 'AI ดึงข้อมูลอัตโนมัติ' : 'AI Auto-Extract Data';

  // ── Smart auto-scan ──────────────────────────────────────────────────────
  String get smartScanPermissionTitle => _isThai
      ? 'ให้แอปช่วยค้นหาสลิปใหม่อัตโนมัติไหม?'
      : 'Allow automatic e-slip discovery?';
  String get smartScanPermissionBody => _isThai
      ? 'แอปขออนุญาตเข้าถึงอัลบั้มภาพเพื่อค้นหาสลิปโอนเงินของเดือนปัจจุบันเท่านั้น และจะคัดกรองเฉพาะรูปที่ยังไม่เคยบันทึก'
      : 'The app needs gallery access to search only this month\'s transfer slips and will skip images already saved.';
  String get smartScanAllow => _isThai ? 'อนุญาตและเริ่มค้นหา' : 'Allow & Scan';
  String get smartScanLater => _isThai ? 'ไว้ก่อน' : 'Maybe Later';
  String get smartScanLoadingGallery => _isThai
      ? 'กำลังค้นหารูปสลิปใหม่ในเดือนนี้...'
      : 'Looking for new slips this month...';
  String get smartScanProcessingAi => _isThai
      ? 'กำลังอ่านสลิปและให้ AI ช่วยบันทึก...'
      : 'Reading slips and asking AI to save them...';
  String smartScanFoundCandidates(int count) => _isThai
      ? 'พบสลิปใหม่ $count ใบ ต้องการให้ AI ช่วยบันทึกหรือไม่?'
      : 'Found $count new slips. Let AI save them?';
  String smartScanCandidateSubtitle(int checkedCount) => _isThai
      ? 'คัดกรองจากรูปใหม่ $checkedCount รูป ด้วย QR Code แล้ว'
      : 'Filtered $checkedCount new images using QR detection.';
  String get smartScanConfirm => _isThai ? 'ให้ AI ช่วยบันทึก' : 'Let AI Save';
  String get smartScanDenied => _isThai
      ? 'ยังไม่ได้รับสิทธิ์เข้าถึงรูปภาพ'
      : 'Gallery permission was not granted';
  String get smartScanNoNew => _isThai
      ? 'ไม่พบสลิปใหม่ที่ยังไม่เคยบันทึก'
      : 'No new unsaved slips found';
  String get smartScanNoCandidates => _isThai
      ? 'ไม่พบรูปที่มี QR Code ในชุดรูปใหม่'
      : 'No QR-code slips found among new images';
  String smartScanCompleted(int savedCount, int failedCount) => _isThai
      ? 'บันทึกอัตโนมัติสำเร็จ $savedCount รายการ ล้มเหลว $failedCount รายการ'
      : 'Auto-save complete: $savedCount saved, $failedCount failed';
  String get smartScanStatusTitle =>
      _isThai ? 'Smart Auto-Scan กำลังทำงาน' : 'Smart Auto-Scan Running';
}
