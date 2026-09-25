import 'package:dio/dio.dart';
import 'local_store.dart';

class ApiClient {
  ApiClient(SessionStore store, {Dio? client})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: 'https://dummyjson.com',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = store.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isRefreshCall = error.requestOptions.path == '/auth/refresh';
          final refreshToken = store.refreshToken;
          if (error.response?.statusCode == 401 &&
              refreshToken != null &&
              !isRefreshCall) {
            try {
              final refreshed = await dio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken, 'expiresInMins': 30},
              );
              await store.saveSession(
                token: refreshed.data['accessToken'] as String,
                refreshToken:
                    refreshed.data['refreshToken'] as String? ?? refreshToken,
                userName: store.userName ?? 'Utilisateur',
              );
              final retry = await dio.fetch(
                error.requestOptions
                  ..headers['Authorization'] = 'Bearer ${store.token}',
              );
              return handler.resolve(retry);
            } on DioException {
              await store.clearSession();
            }
          } else if (error.response?.statusCode == 401) {
            await store.clearSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
}
