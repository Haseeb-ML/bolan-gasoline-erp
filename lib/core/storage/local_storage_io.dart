import 'dart:convert';
import 'dart:io';

import 'local_storage.dart';

class IoLocalStorageAdapter implements LocalStorageAdapter {
  Map<String, String>? _cache;

  File get _storeFile {
    final base = Directory.systemTemp.path;
    return File('$base${Platform.pathSeparator}bolan_gasoline_erp_store.json');
  }

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = _storeFile;
      if (await f.exists()) {
        final raw = await f.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
        return _cache!;
      }
    } catch (_) {}
    _cache = {};
    return _cache!;
  }

  Future<void> _flush() async {
    try {
      await _storeFile.writeAsString(jsonEncode(_cache ?? {}));
    } catch (_) {}
  }

  @override
  Future<String?> read(String key) async {
    final map = await _load();
    return map[key];
  }

  @override
  Future<void> write(String key, String value) async {
    final map = await _load();
    map[key] = value;
    await _flush();
  }

  @override
  Future<void> remove(String key) async {
    final map = await _load();
    map.remove(key);
    await _flush();
  }
}

LocalStorageAdapter createPlatformStorage() => IoLocalStorageAdapter();
