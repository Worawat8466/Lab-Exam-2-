import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class ReceiptTextRecognitionDataSource {
  Future<String> extractText(String imagePath);
}

class ReceiptTextRecognitionDataSourceImpl
    implements ReceiptTextRecognitionDataSource {
  const ReceiptTextRecognitionDataSourceImpl();

  @override
  Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return _normalizeThaiDigits(
        _flattenRecognizedText(recognizedText, lineSeparator: '\n'),
      );
    } finally {
      await recognizer.close();
    }
  }
}

String _normalizeThaiDigits(String input) {
  const thaiDigits = {
    '๐': '0',
    '๑': '1',
    '๒': '2',
    '๓': '3',
    '๔': '4',
    '๕': '5',
    '๖': '6',
    '๗': '7',
    '๘': '8',
    '๙': '9',
  };

  var normalized = input;
  thaiDigits.forEach((thai, arabic) {
    normalized = normalized.replaceAll(thai, arabic);
  });
  return normalized
      .replaceAll('，', ',')
      .replaceAll('．', '.')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}

String _flattenRecognizedText(
  RecognizedText text, {
  String lineSeparator = '\n',
}) {
  final buffer = StringBuffer();
  for (final block in text.blocks) {
    for (final line in block.lines) {
      final value = line.text.trim();
      if (value.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.write(lineSeparator);
      }
      buffer.write(value);
    }
  }
  return buffer.toString();
}
