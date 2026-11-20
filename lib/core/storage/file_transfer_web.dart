import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  try {
    final withBom =
        mimeType.contains('csv') && !content.startsWith('\uFEFF')
            ? '\uFEFF$content'
            : content;
    final blob = web.Blob(
      [withBom.toJS].toJS,
      web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future<void>.delayed(const Duration(seconds: 60), () {
      web.URL.revokeObjectURL(url);
    });
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> downloadBinaryFile({
  required String filename,
  required Uint8List bytes,
  String mimeType = 'application/pdf',
}) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future<void>.delayed(const Duration(seconds: 60), () {
      web.URL.revokeObjectURL(url);
    });
    return true;
  } catch (_) {
    return false;
  }
}

Future<String?> pickJsonFileContent() async {
  final completer = Completer<String?>();
  try {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = '.json,application/json';
    input.onchange = ((web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = web.FileReader();
      reader.onload = ((web.Event _) {
        final result = reader.result;
        if (!completer.isCompleted) {
          completer.complete(result?.dartify()?.toString());
        }
      }).toJS;
      reader.onerror = ((web.Event _) {
        if (!completer.isCompleted) completer.complete(null);
      }).toJS;
      reader.readAsText(file);
    }).toJS;
    input.click();
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }
  return completer.future;
}
