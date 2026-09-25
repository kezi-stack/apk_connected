import 'package:hive_flutter/hive_flutter.dart';

abstract interface class SessionStore {
  String? get token;
  String? get refreshToken;
  String? get userName;
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userName,
  });
  Future<void> clearSession();
  Future<void> cache(String key, String value);
  String? readCache(String key);
}

class LocalStore implements SessionStore {
  LocalStore(this.authBox, this.cacheBox);

  final Box<String> authBox;
  final Box<String> cacheBox;

  @override
  String? get token => authBox.get('accessToken');
  @override
  String? get refreshToken => authBox.get('refreshToken');
  @override
  String? get userName => authBox.get('userName');

  @override
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userName,
  }) async {
    await authBox.put('accessToken', token);
    await authBox.put('refreshToken', refreshToken);
    await authBox.put('userName', userName);
  }

  @override
  Future<void> clearSession() => authBox.clear();

  @override
  Future<void> cache(String key, String value) => cacheBox.put(key, value);
  @override
  String? readCache(String key) => cacheBox.get(key);
}
