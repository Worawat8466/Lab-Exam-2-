class AiCategoryResult {
  const AiCategoryResult({
    required this.category,
    required this.confidence,
    required this.reason,
  });

  final String category;
  final double confidence;
  final String reason;
}
