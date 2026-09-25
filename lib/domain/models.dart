class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.rating,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final double rating;
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    thumbnail: json['thumbnail'] as String,
  );
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.views,
  });

  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final int views;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
    tags: List<String>.from(json['tags'] as List<dynamic>),
    views: json['views'] as int,
  );
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
  });

  final int id;
  final String name;
  final String email;
  final String image;

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as int,
    name: '${json['firstName']} ${json['lastName']}',
    email: json['email'] as String,
    image: json['image'] as String,
  );
}
