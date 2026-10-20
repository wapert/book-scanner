import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../utils/dialogs.dart';
import 'book_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final List<Project> allProjects;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.allProjects,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project get _project => widget.project;

  Future<void> _save() => StorageService.saveProjects(widget.allProjects);

  // ── Create book ────────────────────────────────────────────────────────────

  Future<void> _createBook() async {
    final name = await askName(context, title: 'New Book', hint: 'Book name');
    if (name == null) return;
    final book = Book.create(name);
    setState(() => _project.books.add(book));
    await _save();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            project: _project,
            book: book,
            allProjects: widget.allProjects,
          ),
        ),
      );
    }
  }

  // ── Rename book ────────────────────────────────────────────────────────────

  Future<void> _renameBook(Book book) async {
    final name = await askName(
      context,
      title: 'Rename Book',
      hint: 'Book name',
      initial: book.name,
    );
    if (name == null) return;
    setState(() => book.name = name);
    await _save();
  }

  // ── Delete book ────────────────────────────────────────────────────────────

  Future<void> _deleteBook(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text(
          '"${book.name}" and all ${book.pages.length} page(s) will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _project.books.remove(book));
      await _save();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_project.name),
            Text(
              '${_project.books.length} book${_project.books.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _project.books.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No books yet.\nTap the button below to add a book.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _project.books.length,
              itemBuilder: (ctx, i) {
                final book = _project.books[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.menu_book,
                      color: Color(0xFF1565C0),
                      size: 36,
                    ),
                    title: Text(
                      book.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${book.pages.length} page${book.pages.length == 1 ? '' : 's'} · '
                      'Created ${DateFormat('MMM d, yyyy').format(book.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _renameBook(book);
                        if (v == 'delete') _deleteBook(book);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailScreen(
                              project: _project,
                              book: book,
                              allProjects: widget.allProjects,
                            ),
                          ),
                        ).then(
                          (_) => setState(() {}),
                        ), // refresh page count on return
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }
}
