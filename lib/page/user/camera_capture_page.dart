import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraCapturePage extends StatefulWidget {
  final int initialCamera; // 1 = belakang, 0 = depan
  const CameraCapturePage({super.key, this.initialCamera = 1});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _isTakingPicture = false;
  int _currentCamera = 1;

  // Color palette
  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentCamera = widget.initialCamera;
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
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

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        _isTakingPicture ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengambil foto: $e"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
    });
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview Full Screen
          _controller == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              : FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        _controller!.value.isInitialized) {
                      return CameraPreview(_controller!);
                    }
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    );
                  },
                ),
          
          // Guide Overlay
          _buildGuideOverlay(),
          
          // Top Bar (Close & Switch Camera)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Close
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Tombol Switch Camera
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.cameraswitch_rounded,
                            color: Colors.white, size: 28),
                        onPressed: _switchCamera,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Bar (Galeri & Tombol Ambil Foto)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tombol Galeri
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.photo_library_rounded,
                                color: Colors.white, size: 28),
                            onPressed: _pickFromGallery,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Galeri",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                    
                    // Tombol Ambil Foto (Circular besar)
                    GestureDetector(
                      onTap: _isTakingPicture ? null : _takePicture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _isTakingPicture
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          accentColor),
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt_rounded,
                                    color: secondaryColor,
                                    size: 32,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Spacer untuk keseimbangan (biar tombol kamera di tengah)
                    const SizedBox(width: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Pusatkan objek di dalam bingkai",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}