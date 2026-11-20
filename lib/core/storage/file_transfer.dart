import 'dart:typed_data';

import 'file_transfer_stub.dart'
    if (dart.library.js_interop) 'file_transfer_web.dart' as impl;

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
