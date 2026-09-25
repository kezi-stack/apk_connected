import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/models.dart';
import 'api_client.dart';
import 'local_store.dart';

class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this.api, this.store);
  final ApiClient api;
  final SessionStore store;

  bool get isAuthenticated => store.token != null;
  String? get currentUser => store.userName;

  Future<void> login(String username, String password) async {
    try {
      final response = await api.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      await store.saveSession(
        token: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String? ?? '',
        userName: response.data['firstName'] as String? ?? username,
      );
    } on DioException catch (error) {
      throw AppFailure(
        error.response?.data['message'] as String? ??
            'Connexion impossible. Vérifie tes identifiants.',
      );
    }
  }

  Future<void> register(String firstName, String lastName, String email) async {
    try {
      await api.dio.post(
        '/users/add',
        data: {'firstName': firstName, 'lastName': lastName, 'email': email},
      );
    } on DioException catch (error) {
      throw AppFailure(error.message ?? 'Inscription impossible.');
    }
  }

  Future<void> logout() => store.clearSession();
}

class CatalogRepository {
  CatalogRepository(this.api, this.store);
  final ApiClient api;
  final SessionStore store;

  Future<List<Product>> products() async => _fetchList<Product>(
    cacheKey: 'products',
    path: '/products?limit=12',
    decoder: (json) => Product.fromJson(json),
    fallback: (data) => (data['products'] as List)
        .map((item) => Product.fromJson(item))
        .toList(),
  );

  Future<List<Article>> articles() async => _fetchList<Article>(
    cacheKey: 'articles',
    path: '/posts?limit=12',
    decoder: (json) => Article.fromJson(json),
    fallback: (data) =>
        (data['posts'] as List).map((item) => Article.fromJson(item)).toList(),
  );

  Future<List<Person>> people() async => _fetchList<Person>(
    cacheKey: 'people',
    path: '/users?limit=12',
    decoder: (json) => Person.fromJson(json),
    fallback: (data) =>
        (data['users'] as List).map((item) => Person.fromJson(item)).toList(),
  );

  Future<List<T>> _fetchList<T>({
    required String cacheKey,
    required String path,
    required T Function(Map<String, dynamic>) decoder,
    required List<T> Function(Map<String, dynamic>) fallback,
  }) async {
    try {
      final response = await api.dio.get(path);
      await store.cache(cacheKey, jsonEncode(response.data));
      return fallback(Map<String, dynamic>.from(response.data as Map));
    } on DioException {
      final cached = store.readCache(cacheKey);
      if (cached == null) {
        throw const AppFailure('Aucune donnée disponible hors connexion.');
      }
      return fallback(Map<String, dynamic>.from(jsonDecode(cached) as Map));
    } catch (_) {
      throw const AppFailure('Les données reçues sont invalides.');
    }
  }
}
