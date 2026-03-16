class ExpenseTag {
  const ExpenseTag({
    required this.id,
    required this.name,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
}
