import 'package:web/web.dart' as web;
import 'local_storage.dart';

class WebLocalStorageAdapter implements LocalStorageAdapter {
  @override
  Future<String?> read(String key) async {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  @override
  Future<void> remove(String key) async {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }
}

LocalStorageAdapter createPlatformStorage() => WebLocalStorageAdapter();
