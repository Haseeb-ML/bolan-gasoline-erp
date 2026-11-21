import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

String? lastSavedFilePath;

Future<Directory> _resolveDownloadDirectory() async {
  if (Platform.isAndroid) {
    final candidates = <String>[
      '/storage/emulated/0/Download',
      '/sdcard/Download',
    ];
    try {
      final pkgRaw = File('/proc/self/cmdline').readAsStringSync();
      final pkg = pkgRaw.replaceAll('\x00', '').trim();
      if (pkg.isNotEmpty) {
        candidates.add('/storage/emulated/0/Android/data/$pkg/files/Download');
        candidates.add('/data/user/0/$pkg/files/Download');
      }
    } catch (_) {}

    for (final path in candidates) {
      try {
        final dir = Directory(path);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final probe = File('${dir.path}/.bolan_write_probe');
        probe.writeAsStringSync('ok');
        probe.deleteSync();
        return dir;
      } catch (_) {}
    }
  } else if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final dl = Directory('$userProfile\\Downloads');
      if (dl.existsSync()) return dl;
    }
  } else {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final dl = Directory('$home/Downloads');
      if (dl.existsSync()) return dl;
    }
  }
  return Directory.systemTemp;
}

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  try {
    final dir = await _resolveDownloadDirectory();
    final withBom =
        mimeType.contains('csv') && !content.startsWith('\uFEFF')
            ? '\uFEFF$content'
            : content;
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}$sep$filename');
    await file.writeAsBytes(utf8.encode(withBom), flush: true);
    lastSavedFilePath = file.path;
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
    final dir = await _resolveDownloadDirectory();
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}$sep$filename');
    await file.writeAsBytes(bytes, flush: true);
    lastSavedFilePath = file.path;
    return true;
  } catch (_) {
    return false;
  }
}

Future<String?> pickJsonFileContent() async {
  return null;
}
