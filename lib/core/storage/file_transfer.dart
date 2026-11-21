import 'dart:typed_data';

import 'file_transfer_stub.dart'
    if (dart.library.js_interop) 'file_transfer_web.dart'
    if (dart.library.io) 'file_transfer_io.dart' as impl;

String? get lastSavedFilePath => impl.lastSavedFilePath;

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) =>
    impl.downloadTextFile(
      filename: filename,
      content: content,
      mimeType: mimeType,
    );

Future<bool> downloadBinaryFile({
  required String filename,
  required Uint8List bytes,
  String mimeType = 'application/pdf',
}) =>
    impl.downloadBinaryFile(
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );

Future<String?> pickJsonFileContent() => impl.pickJsonFileContent();

Future<bool> sharePdfFile({
  required String filename,
  required Uint8List bytes,
}) =>
    impl.sharePdfFile(filename: filename, bytes: bytes);

Future<bool> printPdfFile({
  required String filename,
  required Uint8List bytes,
}) =>
    impl.printPdfFile(filename: filename, bytes: bytes);
