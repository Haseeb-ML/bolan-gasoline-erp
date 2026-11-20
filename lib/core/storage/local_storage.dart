import 'local_storage_stub.dart'
    if (dart.library.js_interop) 'local_storage_web.dart'
    if (dart.library.io) 'local_storage_io.dart' as impl;

abstract class LocalStorageAdapter {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

LocalStorageAdapter createLocalStorage() => impl.createPlatformStorage();
