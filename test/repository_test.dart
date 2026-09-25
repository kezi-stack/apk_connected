import 'package:flutter_test/flutter_test.dart';
import 'package:certificat/domain/models.dart';

void main() {
  group('repository data contracts', () {
    test('maps product payload from REST', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Desk',
        'price': 49,
        'rating': 4.5,
        'thumbnail': 'image',
      });
      expect(product.title, 'Desk');
      expect(product.price, 49.0);
      expect(product.rating, 4.5);
    });

    test('maps article tags and metrics from REST', () {
      final article = Article.fromJson({
        'id': 2,
        'title': 'Release',
        'body': 'Notes',
        'tags': ['news', 'team'],
        'views': 120,
      });
      expect(article.tags, contains('team'));
      expect(article.views, 120);
    });

    test('maps user identity for the team screen', () {
      final person = Person.fromJson({
        'id': 3,
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'image': 'avatar',
      });
      expect(person.name, 'Ada Lovelace');
      expect(person.email, 'ada@example.com');
    });
  });
}
