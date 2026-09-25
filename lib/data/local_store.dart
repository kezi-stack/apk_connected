import 'package:hive_flutter/hive_flutter.dart';

class LocalStore {
  LocalStore(this.authBox, this.cacheBox);

  final Box<String> authBox;
  final Box<String> cacheBox;

  String? get token => authBox.get('accessToken');
  String? get userName => authBox.get('userName');

  Future<void> saveSession({
    required String token,
    required String userName,
  }) async {
    await authBox.put('accessToken', token);
    await authBox.put('userName', userName);
  }

  Future<void> clearSession() => authBox.clear();

  Future<void> cache(String key, String value) => cacheBox.put(key, value);
  String? readCache(String key) => cacheBox.get(key);
}
