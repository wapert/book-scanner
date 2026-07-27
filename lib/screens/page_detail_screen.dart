import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/page_item.dart';
import '../services/ocr_service.dart';

/// Views a single page's photo and lets the user edit / (re-)run OCR on its
/// text. Returns true via Navigator.pop if the text was changed and saved.
class PageDetailScreen extends StatefulWidget {
  final PageItem page;
  final int pageNumber;

  const PageDetailScreen({
    super.key,
    required this.page,
    required this.pageNumber,
  });

  @override
  State<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends State<PageDetailScreen> {
  late final TextEditingController _textCtrl;
  bool _running = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.page.text);
    _textCtrl.addListener(() {
      if (_textCtrl.text != widget.page.text && !_dirty) {
        setState(() => _dirty = true);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final text = widget.page.isRemote
          ? await OcrService.recognizeUrl(widget.page.photoUrl)
          : await OcrService.recognizeFile(widget.page.photoUrl);
      _textCtrl.text = text;
      setState(() => _dirty = true);
      if (mounted && text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found on this page')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('OCR failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _save() {
    widget.page.text = _textCtrl.text;
    Navigator.pop(context, true);
  }

  Widget _image() {
    if (widget.page.isRemote) {
      return CachedNetworkImage(
        imageUrl: widget.page.photoUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    final file = File(widget.page.photoUrl);
    return file.existsSync()
        ? Image.file(file, fit: BoxFit.contain, cacheWidth: 1280)
        : const Icon(Icons.broken_image);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your edits to this page have not been saved.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep editing')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (discard != true) return;
        if (!mounted) return;
        Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Page ${widget.pageNumber}'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            if (_dirty)
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: _save,
              ),
          ],
        ),
        body: Column(
          children: [
            // Photo (tap to view fullscreen)
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Container(color: Colors.black, child: _image()),
            ),
            // Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Recognized text',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (OcrService.isSupported)
                    TextButton.icon(
                      onPressed: _running ? null : _runOcr,
                      icon: _running
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.document_scanner, size: 18),
                      label: Text(widget.page.hasText ? 'Re-run OCR' : 'Run OCR'),
                    )
                  else
                    const Text('OCR: Android only',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            // Editable text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'No text yet. Tap "Run OCR" to extract text from the photo, or type here.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
