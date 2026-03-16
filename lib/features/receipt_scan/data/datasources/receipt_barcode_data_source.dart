import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

abstract class ReceiptBarcodeDataSource {
  Future<bool> hasQrCode(String imagePath);
}

class ReceiptBarcodeDataSourceImpl implements ReceiptBarcodeDataSource {
  const ReceiptBarcodeDataSourceImpl();

  @override
  Future<bool> hasQrCode(String imagePath) async {
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }

    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await scanner.processImage(inputImage);
      return barcodes.any((barcode) => barcode.format == BarcodeFormat.qrCode);
    } finally {
      await scanner.close();
    }
  }
}
