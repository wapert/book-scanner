import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen. Returns the permanent [String] photo path on success,
/// or null if the user cancels.
///
/// [bookId] is used to organise photos into per-book folders.
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

  /// If not null we are showing the photo-preview state.
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

  // ── Confirm: copy temp file to permanent storage ───────────────────────────

  Future<void> _confirm() async {
    if (_previewPath == null) return;
    try {
      final permanent = await _savePermanently(_previewPath!, widget.bookId);
      if (mounted) Navigator.pop(context, permanent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  void _retake() => setState(() => _previewPath = null);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _previewPath != null
            ? _buildPreview()
            : _buildCamera(),
      ),
    );
  }

  // ── Camera view ────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    return Stack(children: [
      // Preview
      if (_initialized && _controller != null)
        Positioned.fill(child: CameraPreview(_controller!))
      else
        const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('Starting camera…',
                style: TextStyle(color: Colors.white)),
          ]),
        ),

      // Top bar
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

      // Bottom bar
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
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 32),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }

  // ── Photo preview view ─────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Column(children: [
      // Toolbar
      Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Retake',
            onPressed: _retake,
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
            onPressed: _confirm,
          ),
        ]),
      ),

      // Full photo
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
              onPressed: _retake,
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
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: const Text('Add to Book'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Save photo to permanent location ─────────────────────────────────────────

Future<String> _savePermanently(String tempPath, String bookId) async {
  Directory base;
  if (Platform.isAndroid) {
    base = (await getExternalStorageDirectory())!;
  } else {
    base = await getApplicationDocumentsDirectory();
  }
  final dir = Directory('${base.path}/BookScanner/photos/$bookId');
  await dir.create(recursive: true);
  final dest = File(
      '${dir.path}/page_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await File(tempPath).copy(dest.path);
  return dest.path;
}
