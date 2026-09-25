import 'package:certificat/data/api_client.dart';
import 'package:certificat/data/local_store.dart';
import 'package:certificat/data/repositories.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class FakeStore implements SessionStore {
  String? storedToken;
  String? storedRefresh;
  String? storedUser;
  final values = <String, String>{};
  @override
  String? get token => storedToken;
  @override
  String? get refreshToken => storedRefresh;
  @override
  String? get userName => storedUser;
  @override
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userName,
  }) async {
    storedToken = token;
    storedRefresh = refreshToken;
    storedUser = userName;
  }

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedRefresh = null;
    storedUser = null;
  }

  @override
  Future<void> cache(String key, String value) async => values[key] = value;
  @override
  String? readCache(String key) => values[key];
}

void main() {
  late MockDio dio;
  late FakeStore store;
  late CatalogRepository repository;
  setUp(() {
    dio = MockDio();
    store = FakeStore();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = CatalogRepository(ApiClient(store, client: dio), store);
  });

  test('repository fetches and caches products from REST', () async {
    when(() => dio.get('/products?limit=12')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/products?limit=12'),
        data: {
          'products': [
            {
              'id': 1,
              'title': 'Desk',
              'price': 49,
              'rating': 4.5,
              'thumbnail': 'image',
            },
          ],
        },
      ),
    );
    final products = await repository.products();
    expect(products.single.title, 'Desk');
    expect(store.readCache('products'), contains('Desk'));
    verify(() => dio.get('/products?limit=12')).called(1);
  });

  test('repository reads cached articles when network fails', () async {
    await store.cache(
      'articles',
      '{"posts":[{"id":2,"title":"Release","body":"Notes","tags":["news"],"views":120}]}',
    );
    when(() => dio.get('/posts?limit=12')).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/posts?limit=12')),
    );
    final articles = await repository.articles();
    expect(articles.single.title, 'Release');
    expect(articles.single.views, 120);
  });

  test('repository reports a useful offline error without cache', () async {
    when(() => dio.get('/users?limit=12')).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/users?limit=12')),
    );
    expect(() => repository.people(), throwsA(isA<AppFailure>()));
  });
}
