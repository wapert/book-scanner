import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/book.dart';
import '../models/project.dart';
import '../services/pdf_exporter.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
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

  Future<void> _save() => StorageService.saveProjects(widget.allProjects);

  // ── Scan a new page ────────────────────────────────────────────────────────

  Future<void> _scanPage() async {
    final url = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(bookId: _book.id),
      ),
    );
    if (url == null) return;

    setState(() => _book.pages.add(url));
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page ${_book.pages.length} added')),
      );
    }
  }

  // ── Delete page ────────────────────────────────────────────────────────────

  Future<void> _deletePage(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete page?'),
        content: Text('Page ${index + 1} will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final path = _book.pages[index];
    setState(() => _book.pages.removeAt(index));
    await _save();

    // Delete from Firebase Storage (URL) or local file system
    if (path.startsWith('http')) {
      await PhotoService.deletePhoto(path);
    } else {
      try { await File(path).delete(); } catch (_) {}
    }
  }

  // ── View full-screen ───────────────────────────────────────────────────────

  void _viewPhoto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenPhotoScreen(
          paths: _book.pages,
          initialIndex: index,
        ),
      ),
    );
  }

  // ── Export as PDF ──────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_book.pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pages to export yet')));
      return;
    }
    try {
      final file = await PdfExporter.export(_book.pages, _book.name);
      if (!mounted) return;
      final saveLocation =
          Platform.isMacOS ? '~/Downloads/BookScanner' : 'Documents/BookScanner';
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
                child: const Text('Done')),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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
            Text(_book.name),
            Text(
              '${_book.pages.length} page${_book.pages.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: _book.pages.isEmpty
          ? Center(
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
            )
          : GridView.builder(
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
                path: _book.pages[i],
                onTap: () => _viewPhoto(i),
                onDelete: () => _deletePage(i),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanPage,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Page'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── Shared image widget ────────────────────────────────────────────────────────

Widget _photoWidget(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: path,
      fit: fit,
      placeholder: (_, __) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image),
      ),
    );
  }
  final file = File(path);
  return file.existsSync()
      ? Image.file(file, fit: fit)
      : Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image));
}

// ── Page grid tile ────────────────────────────────────────────────────────────

class _PageTile extends StatelessWidget {
  final int index;
  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PageTile({
    required this.index,
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete page',
                    style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); onDelete(); },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(fit: StackFit.expand, children: [
          _photoWidget(path),
          Positioned(
            top: 6, left: 6,
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
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Fullscreen photo viewer ───────────────────────────────────────────────────

class _FullscreenPhotoScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _FullscreenPhotoScreen(
      {required this.paths, required this.initialIndex});

  @override
  State<_FullscreenPhotoScreen> createState() => _FullscreenPhotoScreenState();
}

class _FullscreenPhotoScreenState extends State<_FullscreenPhotoScreen> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Page ${_current + 1} of ${widget.paths.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) => InteractiveViewer(
          child: Center(
            child: _photoWidget(widget.paths[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
