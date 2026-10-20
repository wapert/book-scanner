import 'package:flutter_test/flutter_test.dart';

import 'package:book_scanner/models/book.dart';
import 'package:book_scanner/models/page_item.dart';
import 'package:book_scanner/models/project.dart';

void main() {
  test('project hierarchy survives JSON serialization', () {
    final project = Project(
      id: 'project-1',
      name: 'Research',
      createdAt: DateTime.utc(2026, 7, 28),
      books: [
        Book(
          id: 'book-1',
          name: 'Reference Book',
          createdAt: DateTime.utc(2026, 7, 28),
          pages: [
            PageItem(
              photoUrl: 'https://example.com/page.jpg',
              text: 'Recognized text',
            ),
          ],
        ),
      ],
    );

    final restored = Project.fromJson(project.toJson());

    expect(restored.id, project.id);
    expect(restored.name, 'Research');
    expect(restored.books.single.name, 'Reference Book');
    expect(restored.books.single.pages.single.text, 'Recognized text');
  });

  test('legacy photo-only pages are migrated', () {
    final book = Book.fromJson({
      'id': 'book-1',
      'name': 'Legacy Book',
      'createdAt': '2026-07-28T00:00:00.000Z',
      'pages': ['https://example.com/legacy.jpg'],
    });

    expect(book.pages.single.photoUrl, 'https://example.com/legacy.jpg');
    expect(book.pages.single.text, isEmpty);
  });
}
