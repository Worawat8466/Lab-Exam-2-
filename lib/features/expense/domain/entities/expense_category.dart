class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    this.emoji,
    this.colorHex,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? emoji;
  final String? colorHex;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
