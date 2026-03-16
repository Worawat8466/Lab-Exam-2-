class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    this.colorHex,
  });

  final String categoryName;
  final double totalAmount;
  final double percentage;
  final String? colorHex;
}
