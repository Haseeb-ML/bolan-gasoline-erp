import 'dart:typed_data';

String? lastSavedFilePath;

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  return false;
}

Future<bool> downloadBinaryFile({
  required String filename,
  required Uint8List bytes,
  String mimeType = 'application/pdf',
}) async {
  return false;
}

Future<String?> pickJsonFileContent() async {
  return null;
}

Future<bool> sharePdfFile({
  required String filename,
  required Uint8List bytes,
}) async {
  return true;
}

Future<bool> printPdfFile({
  required String filename,
  required Uint8List bytes,
}) async {
  return true;
}
