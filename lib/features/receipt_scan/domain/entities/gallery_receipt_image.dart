class GalleryReceiptImage {
  const GalleryReceiptImage({
    required this.assetId,
    required this.localPath,
    required this.createdAt,
    required this.width,
    required this.height,
  });

  final String assetId;
  final String localPath;
  final DateTime createdAt;
  final int width;
  final int height;
}
