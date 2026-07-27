import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/page_item.dart';
import '../services/image_service.dart';
import '../services/ocr_service.dart';
import '../services/photo_service.dart';

/// Camera screen. Returns a [PageItem] (compressed photo URL + OCR text) on
/// success, or null if the user cancels.
class ScanScreen extends StatefulWidget {
  final String bookId;
  const ScanScreen({super.key, required this.bookId});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initialized = false;
  bool _capturing = false;
  bool _uploading = false;
  double _uploadProgress = 0;
  String _statusText = '';

  /// Local temp path from the camera (preview state).
  String? _previewPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
      if (mounted) setState(() => _initialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Camera setup ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
        Navigator.pop(context);
      }
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final ctrl = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await ctrl.initialize();
    if (!mounted) { ctrl.dispose(); return; }
    setState(() { _controller = ctrl; _initialized = true; });
  }

  // ── Capture ────────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !_initialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xfile = await ctrl.takePicture();
      setState(() { _previewPath = xfile.path; _capturing = false; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
      setState(() => _capturing = false);
    }
  }

  // ── Confirm: compress → OCR → upload ──────────────────────────────────────

  Future<void> _confirm() async {
    if (_previewPath == null || _uploading) return;
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _statusText = 'Compressing…';
    });
    try {
      // 1. Compress (resize + JPEG) off the UI thread.
      final compressed = await ImageService.compress(_previewPath!);

      // 2. On-device OCR (Android only). Failures here are non-fatal — the
      //    user can re-run OCR later from the page screen.
      String text = '';
      if (OcrService.isSupported) {
        if (mounted) setState(() => _statusText = 'Recognizing text…');
        try {
          text = await OcrService.recognizeFile(compressed);
        } catch (_) {}
      }

      // 3. Upload the compressed image.
      if (mounted) setState(() => _statusText = 'Uploading…');
      final url = await PhotoService.uploadPhoto(
        compressed,
        widget.bookId,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (mounted) Navigator.pop(context, PageItem(photoUrl: url, text: text));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _uploading = false);
      }
    }
  }

  void _retake() => setState(() { _previewPath = null; _uploading = false; });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _previewPath != null ? _buildPreview() : _buildCamera(),
      ),
    );
  }

  // ── Camera view ────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    return Stack(children: [
      if (_initialized && _controller != null)
        Positioned.fill(child: CameraPreview(_controller!))
      else
        const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('Starting camera…', style: TextStyle(color: Colors.white)),
          ]),
        ),

      Positioned(
        top: 0, left: 0, right: 0,
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('Scan Page',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),

      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          color: Colors.black87,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Point at a book page and tap the button',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            if (_capturing)
              const CircularProgressIndicator(color: Colors.white)
            else
              GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1565C0),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }

  // ── Photo preview view ─────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Stack(children: [
      Column(children: [
        // Toolbar
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Retake',
              onPressed: _uploading ? null : _retake,
            ),
            const Expanded(
              child: Text('Use this photo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle,
                  color: Colors.greenAccent, size: 32),
              tooltip: 'Add to book',
              onPressed: _uploading ? null : _confirm,
            ),
          ]),
        ),

        // Full photo (local temp file for preview)
        Expanded(
          child: Image.file(
            File(_previewPath!),
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),

        // Action buttons
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _retake,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retake',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _uploading ? null : _confirm,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Add to Book'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0)),
              ),
            ),
          ]),
        ),
      ]),

      // Upload overlay
      if (_uploading)
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_statusText.isEmpty ? 'Working…' : _statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: (_statusText == 'Uploading…' && _uploadProgress > 0)
                        ? _uploadProgress
                        : null,
                    color: const Color(0xFF1565C0),
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 8),
                if (_statusText == 'Uploading…' && _uploadProgress > 0)
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ]),
            ),
          ),
        ),
    ]);
  }
}
