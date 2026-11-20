import 'local_storage.dart';

class MemoryStorageAdapter implements LocalStorageAdapter {
  final Map<String, String> _mem = {};

  @override
  Future<String?> read(String key) async => _mem[key];

  @override
  Future<void> write(String key, String value) async {
    _mem[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _mem.remove(key);
  }
}

LocalStorageAdapter createPlatformStorage() => MemoryStorageAdapter();
