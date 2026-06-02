class Book {
  final String id;
  String name;
  final DateTime createdAt;

  /// Each entry is an absolute path to a saved JPEG photo.
  List<String> pages;

  Book({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? pages,
  }) : pages = pages ?? [];

  factory Book.create(String name) => Book(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      );

  factory Book.fromJson(Map<String, dynamic> j) {
    final rawPages = (j['pages'] as List?) ?? [];

    // Migration: previous versions stored strings (OCR text) or PageData
    // objects. Extract the photoPath where possible; skip text-only entries.
    final pages = rawPages
        .map((p) {
          if (p is Map) {
            // PageData format from previous build
            return (p['photoPath'] as String?) ?? '';
          }
          if (p is String && p.startsWith('/')) {
            // Already a file path
            return p;
          }
          return ''; // OCR text from old build — discard
        })
        .where((s) => s.isNotEmpty)
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
        'pages': pages,
      };
}
