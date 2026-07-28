import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/book.dart';
import '../models/page_item.dart';
import '../models/project.dart';
import '../services/pdf_exporter.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
import 'page_detail_screen.dart';
import 'scan_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Project project;
  final Book book;
  final List<Project> allProjects;

  const BookDetailScreen({
    super.key,
    required this.project,
    required this.book,
    required this.allProjects,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book get _book => widget.book;

  bool _selecting = false;
  bool _reordering = false;
  final Set<int> _selected = {};

  Future<bool> _save() async {
    try {
      await StorageService.saveProjects(widget.allProjects);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
      return false;
    }
  }

  // ── Scan a new page ────────────────────────────────────────────────────────

  Future<void> _scanPage() async {
    final page = await Navigator.push<PageItem>(
      context,
      MaterialPageRoute(builder: (_) => ScanScreen(bookId: _book.id)),
    );
    if (page == null) return;

    setState(() => _book.pages.add(page));
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page ${_book.pages.length} added')),
      );
    }
  }

  // ── Open a page ──────────────────────────────────────────────────────────

  Future<void> _openPage(int index) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PageDetailScreen(page: _book.pages[index], pageNumber: index + 1),
      ),
    );
    if (changed == true) {
      setState(() {});
      await _save();
    }
  }

  // ── Delete pages ───────────────────────────────────────────────────────────

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count page${count == 1 ? '' : 's'}?'),
        content: const Text('This cannot be undone.'),
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
    if (ok != true) return;

    final toDelete = _selected.toList()..sort((a, b) => b.compareTo(a));
    final urls = toDelete.map((i) => _book.pages[i].photoUrl).toList();
    setState(() {
      for (final i in toDelete) {
        _book.pages.removeAt(i);
      }
      _exitSelection();
    });
    await _save();
    // Best-effort cleanup of storage objects.
    for (final url in urls) {
      if (url.startsWith('http')) {
        await PhotoService.deletePhoto(url);
      } else {
        try {
          await File(url).delete();
        } catch (_) {}
      }
    }
  }

  // ── Move pages to another book ─────────────────────────────────────────────

  Future<void> _moveSelected() async {
    final target = await _pickTargetBook();
    if (target == null) return;

    final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
    final moving =
        indices.map((i) => _book.pages[i]).toList().reversed.toList();
    setState(() {
      for (final i in indices) {
        _book.pages.removeAt(i);
      }
      target.pages.addAll(moving);
      _exitSelection();
    });
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved ${moving.length} page(s) to "${target.name}"'),
        ),
      );
    }
  }

  Future<Book?> _pickTargetBook() async {
    // All books across all projects except this one.
    final options = <(String, Book)>[];
    for (final p in widget.allProjects) {
      for (final b in p.books) {
        if (b.id != _book.id) options.add((p.name, b));
      }
    }
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other book to move to. Create one first.'),
        ),
      );
      return null;
    }
    return showModalBottomSheet<Book>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Move to book',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (projName, b) in options)
                    ListTile(
                      leading: const Icon(
                        Icons.menu_book,
                        color: Color(0xFF1565C0),
                      ),
                      title: Text(b.name),
                      subtitle: Text(
                        '$projName · ${b.pages.length} page${b.pages.length == 1 ? '' : 's'}',
                      ),
                      onTap: () => Navigator.pop(ctx, b),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Selection mode helpers ─────────────────────────────────────────────────

  void _enterSelection(int index) {
    setState(() {
      _selecting = true;
      _selected.add(index);
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
        if (_selected.isEmpty) _selecting = false;
      } else {
        _selected.add(index);
      }
    });
  }

  void _exitSelection() {
    _selecting = false;
    _selected.clear();
  }

  // ── Export as PDF ──────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_book.pages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No pages to export yet')));
      return;
    }
    try {
      final urls = _book.pages.map((p) => p.photoUrl).toList();
      final file = await PdfExporter.export(urls, _book.name);
      if (!mounted) return;
      final saveLocation = Platform.isMacOS
          ? '~/Downloads/BookScanner'
          : 'Documents/BookScanner';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PDF saved!'),
          content: Text(
            '"${_book.name}.pdf"\n'
            '${_book.pages.length} page(s) saved to $saveLocation',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await OpenFilex.open(file.path);
              },
              child: const Text('Open PDF'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selecting ? _selectionAppBar() : _normalAppBar(),
      body: _book.pages.isEmpty
          ? _emptyState()
          : _reordering
              ? _reorderList()
              : _grid(),
      floatingActionButton: (_selecting || _reordering)
          ? null
          : FloatingActionButton.extended(
              onPressed: _scanPage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Page'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
    );
  }

  AppBar _normalAppBar() => AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_book.name),
            Text(
              '${_book.pages.length} page${_book.pages.length == 1 ? '' : 's'}'
              '${_reordering ? ' · reordering' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: _reordering
            ? [
                TextButton(
                  onPressed: () async {
                    setState(() => _reordering = false);
                    await _save();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ]
            : [
                if (_book.pages.length > 1)
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: 'Reorder pages',
                    onPressed: () => setState(() => _reordering = true),
                  ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export PDF',
                  onPressed: _exportPdf,
                ),
              ],
      );

  AppBar _selectionAppBar() => AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(_exitSelection),
        ),
        title: Text('${_selected.length} selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            tooltip: 'Move to book',
            onPressed: _selected.isEmpty ? null : _moveSelected,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: _selected.isEmpty ? null : _deleteSelected,
          ),
        ],
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pages yet.\nTap the button below to scan the first page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );

  Widget _grid() => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3 / 4,
        ),
        itemCount: _book.pages.length,
        itemBuilder: (ctx, i) => _PageTile(
          index: i,
          page: _book.pages[i],
          selecting: _selecting,
          selected: _selected.contains(i),
          onTap: () => _selecting ? _toggle(i) : _openPage(i),
          onLongPress: () => _selecting ? null : _enterSelection(i),
        ),
      );

  Widget _reorderList() => ReorderableListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _book.pages.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _book.pages.removeAt(oldIndex);
            _book.pages.insert(newIndex, item);
          });
        },
        itemBuilder: (ctx, i) {
          final page = _book.pages[i];
          return Card(
            key: ValueKey('reorder_$i${page.photoUrl}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: SizedBox(width: 48, height: 60, child: _thumb(page)),
              title: Text('Page ${i + 1}'),
              subtitle: page.hasText
                  ? const Text('Has text', style: TextStyle(fontSize: 12))
                  : null,
              trailing: const Icon(Icons.drag_handle),
            ),
          );
        },
      );

  Widget _thumb(PageItem page) {
    if (page.isRemote) {
      return CachedNetworkImage(imageUrl: page.photoUrl, fit: BoxFit.cover);
    }
    final f = File(page.photoUrl);
    return f.existsSync()
        ? Image.file(f, fit: BoxFit.cover)
        : Container(color: Colors.grey[300]);
  }
}

// ── Page grid tile ────────────────────────────────────────────────────────────

class _PageTile extends StatelessWidget {
  final int index;
  final PageItem page;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PageTile({
    required this.index,
    required this.page,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  Widget _photo() {
    if (page.isRemote) {
      return CachedNetworkImage(
        imageUrl: page.photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    }
    final f = File(page.photoUrl);
    return f.existsSync()
        ? Image.file(f, fit: BoxFit.cover)
        : Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _photo(),
            // Page number badge
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Page ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // "Has text" indicator
            if (page.hasText)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.text_snippet, color: Colors.white, size: 20),
              ),
            // Selection overlay
            if (selecting)
              Container(
                color: selected
                    ? const Color(0xFF1565C0).withValues(alpha: 0.35)
                    : Colors.black12,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(6),
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
