class ReceiptScanResult {
  const ReceiptScanResult({
    required this.rawText,
    required this.imagePath,
    required this.scannedAt,
  });

  final String rawText;
  final String imagePath;
  final DateTime scannedAt;
}
