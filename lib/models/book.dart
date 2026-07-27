import 'page_item.dart';

class Book {
  final String id;
  String name;
  final DateTime createdAt;

  List<PageItem> pages;

  Book({
    required this.id,
    required this.name,
    required this.createdAt,
    List<PageItem>? pages,
  }) : pages = pages ?? [];

  factory Book.create(String name) => Book(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      );

  factory Book.fromJson(Map<String, dynamic> j) {
    final rawPages = (j['pages'] as List?) ?? [];

    // Migration across formats:
    //  - PageItem map  {photoUrl, text}       ← current
    //  - String URL/path                       ← photo-only build
    //  - {photoPath: ...}                       ← very old build
    //  - OCR text string (no scheme)            ← oldest build, discarded
    final pages = rawPages
        .map<PageItem?>((p) {
          if (p is Map) {
            final map = Map<String, dynamic>.from(p);
            if (map['photoUrl'] != null) return PageItem.fromJson(map);
            final legacyPath = map['photoPath'] as String?;
            if (legacyPath != null && legacyPath.isNotEmpty) {
              return PageItem(photoUrl: legacyPath);
            }
            return null;
          }
          if (p is String && (p.startsWith('/') || p.startsWith('http'))) {
            return PageItem(photoUrl: p);
          }
          return null;
        })
        .whereType<PageItem>()
        .toList();

    return Book(
      id: j['id'] as String,
      name: j['name'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      pages: pages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };
}
