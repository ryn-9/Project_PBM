import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraCapturePage extends StatefulWidget {
  final int initialCamera; // 1 = belakang, 0 = depan
  CameraCapturePage({super.key, this.initialCamera = 1});

  @override
  _CameraCapturePageState createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _isTakingPicture = false;
  File? _selectedImage;
  int _currentCamera = 1;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.initialCamera;
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final selectedCamera = (_currentCamera == 1)
        ? cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first)
        : cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first);

    _controller = CameraController(selectedCamera, ResolutionPreset.high);
    _initializeFuture = _controller!.initialize();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _takePicture() async {
    if (_controller == null || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      await _initializeFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.pop(context, image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil foto: $e")));
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final result = await _picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      Navigator.pop(context, result.path);
    }
  }

  void _switchCamera() {
    setState(() {
      _currentCamera = _currentCamera == 1 ? 0 : 1;
      _initCamera();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(title: const Text("Ambil Foto"), backgroundColor: Colors.black),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTakingPicture ? null : _takePicture,
                icon: _isTakingPicture
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isTakingPicture ? "Mengambil..." : "Ambil Foto"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text("Pilih Galeri"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.switch_camera, color: Colors.white),
              onPressed: _switchCamera,
            ),
          ],
        ),
      ),
    );
  }
}