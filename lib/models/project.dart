import 'book.dart';

class Project {
  final String id;
  String name;
  final DateTime createdAt;
  List<Book> books;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    List<Book>? books,
  }) : books = books ?? [];

  factory Project.create(String name) => Project(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: name,
    createdAt: DateTime.now(),
  );

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'] as String,
    name: j['name'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    books: (j['books'] as List)
        .map((b) => Book.fromJson(b as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'books': books.map((b) => b.toJson()).toList(),
  };
}
