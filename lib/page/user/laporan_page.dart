import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:latlong2/latlong.dart';

import 'camera_capture_page.dart';

class LaporanPage extends StatefulWidget {
  final int userId;
  final String? initialImagePath;
  final VoidCallback? onReportSubmitted;

  const LaporanPage({
    super.key,
    required this.userId,
    this.initialImagePath,
    this.onReportSubmitted,
  });

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController judulController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  File? imageFile;
  LatLng? _currentLatLng;
  Marker? _marker;
  String? lokasi;

  bool isPublic = true;
  bool isLoading = false;
  bool isLoadingLocation = false;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _setInitialImage();
  }

  @override
  void didUpdateWidget(covariant LaporanPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialImagePath != oldWidget.initialImagePath) {
      _setInitialImage();
    }
  }

  void _setInitialImage() {
    if (widget.initialImagePath != null &&
        widget.initialImagePath!.isNotEmpty) {
      setState(() {
        imageFile = File(widget.initialImagePath!);
      });
    }
  }

  Future<void> pickCamera() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(),
      ),
    );

    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        imageFile = File(imagePath);
      });
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String?>[
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ];

    final cleanedParts = <String>[];

    for (final part in parts) {
      final value = part?.trim();

      if (value != null &&
          value.isNotEmpty &&
          !cleanedParts.contains(value)) {
        cleanedParts.add(value);
      }
    }

    return cleanedParts.join(', ');
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    final placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
      localeIdentifier: 'id_ID',
    );

    if (placemarks.isEmpty) {
      return '';
    }

    return _formatAddress(placemarks.first);
  }

  Future<void> getLocation() async {
    setState(() {
      isLoadingLocation = true;
      alamatController.text = 'Mengambil alamat otomatis...';
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          alamatController.clear();
        });

        _showSnackBar(
          message: "Izin lokasi diperlukan untuk mengambil lokasi",
          color: secondaryColor,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          alamatController.clear();
        });

        _showSnackBar(
          message:
              "Izin lokasi ditolak permanen, silakan izinkan dari pengaturan",
          color: secondaryColor,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(pos.latitude, pos.longitude);

      final koordinat =
          "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";

      String alamatOtomatis = '';

      try {
        alamatOtomatis = await _getAddressFromLatLng(latLng);
      } catch (_) {
        alamatOtomatis = '';
      }

      if (!mounted) return;

      setState(() {
        _currentLatLng = latLng;

        _marker = Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: accentColor,
            size: 40,
          ),
        );

        lokasi = koordinat;

        alamatController.text = alamatOtomatis.isNotEmpty
            ? alamatOtomatis
            : 'Alamat tidak ditemukan otomatis. Koordinat: $koordinat';

        isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        alamatController.clear();
      });

      _showSnackBar(
        message: "Gagal mendapatkan lokasi: $e",
        color: secondaryColor,
      );
    }
  }

  MediaType _getImageMediaType(String path) {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<void> submitLaporan() async {
    if (imageFile == null ||
        judulController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        alamatController.text.trim().isEmpty ||
        _currentLatLng == null) {
      _showSnackBar(
        message: "Lengkapi foto, judul, deskripsi, alamat, dan lokasi!",
        color: secondaryColor,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://wadulguse-api.vercel.app/api/laporan"),
      );

      final jenisLaporan = isPublic ? "public" : "private";

      request.fields["user_id"] = widget.userId.toString();
      request.fields["judul"] = judulController.text.trim();
      request.fields["deskripsi"] = descController.text.trim();
      request.fields["latitude"] = _currentLatLng!.latitude.toString();
      request.fields["longitude"] = _currentLatLng!.longitude.toString();
      request.fields["alamat"] = alamatController.text.trim();
      request.fields["jenis_laporan"] = jenisLaporan;

      request.files.add(
        await http.MultipartFile.fromPath(
          "media",
          imageFile!.path,
          contentType: _getImageMediaType(imageFile!.path),
        ),
      );

      print("POST /api/laporan");
      print("user_id: ${widget.userId}");
      print("judul: ${judulController.text.trim()}");
      print("deskripsi: ${descController.text.trim()}");
      print("latitude: ${_currentLatLng!.latitude}");
      print("longitude: ${_currentLatLng!.longitude}");
      print("alamat: ${alamatController.text.trim()}");
      print("jenis_laporan: $jenisLaporan");
      print("media ada: ${imageFile != null}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        _showSnackBar(
          message: "✓ Laporan berhasil dikirim!",
          color: Colors.green.shade700,
        );

        judulController.clear();
        descController.clear();
        alamatController.clear();

        setState(() {
          imageFile = null;
          _currentLatLng = null;
          _marker = null;
          lokasi = null;
        });

        widget.onReportSubmitted?.call();
      } else {
        if (!mounted) return;

        _showSnackBar(
          message: "Gagal: ${response.statusCode} - ${response.body}",
          color: secondaryColor,
        );
      }
    } catch (e) {
      if (!mounted) return;

      print("ERROR SUBMIT LAPORAN: $e");

      _showSnackBar(
        message: "Error submit laporan: $e",
        color: secondaryColor,
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar({
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    judulController.dispose();
    descController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "FORM LAPORAN",
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Buat Laporan",
            style: TextStyle(
              color: dominantColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ambil foto dari kamera, lalu lengkapi data laporan",
            style: TextStyle(
              color: dominantColor.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: secondaryColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: secondaryColor.withOpacity(0.4),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: accentColor,
        size: 20,
      ),
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dominantColor.withOpacity(0.8),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: accentColor,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _photoSection() {
    return GestureDetector(
      onTap: pickCamera,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: imageFile != null ? 210 : 140,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: imageFile != null
                ? accentColor
                : dominantColor.withOpacity(0.75),
            width: imageFile != null ? 2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      imageFile!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              color: dominantColor,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Ganti Foto",
                              style: TextStyle(
                                color: dominantColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: accentColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ketuk untuk ambil foto",
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Bisa dari halaman ini atau dari navbar kamera",
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _descriptionField() {
    return TextField(
      controller: descController,
      maxLines: 4,
      style: const TextStyle(
        color: secondaryColor,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: "Jelaskan kondisi kerusakan secara detail...",
        hintStyle: TextStyle(
          color: secondaryColor.withOpacity(0.4),
          fontSize: 14,
        ),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dominantColor.withOpacity(0.8),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: accentColor,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _gpsButton() {
    return GestureDetector(
      onTap: isLoadingLocation ? null : getLocation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: _currentLatLng != null ? accentColor.withOpacity(0.1) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _currentLatLng != null
                ? accentColor
                : dominantColor.withOpacity(0.75),
            width: _currentLatLng != null ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isLoadingLocation)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            else
              Icon(
                _currentLatLng != null
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: accentColor,
                size: 20,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoadingLocation
                        ? "Mengambil lokasi..."
                        : _currentLatLng != null
                            ? "Lokasi GPS ditemukan"
                            : "Ambil Lokasi GPS",
                    style: const TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (lokasi != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      lokasi!,
                      style: TextStyle(
                        color: secondaryColor.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_currentLatLng != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Ubah",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapPreview() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _currentLatLng == null
          ? const SizedBox.shrink()
          : Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dominantColor.withOpacity(0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLatLng!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.project_pbm',
                    ),
                    MarkerLayer(
                      markers: _marker != null ? [_marker!] : [],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _visibilityOption({
    required String label,
    required IconData icon,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? accentColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? accentColor : secondaryColor.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: selected
                            ? secondaryColor
                            : secondaryColor.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryColor.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visibilitySection() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dominantColor.withOpacity(0.75),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _visibilityOption(
            label: "Publik",
            icon: Icons.public_rounded,
            subtitle: "Semua dapat melihat",
            selected: isPublic,
            onTap: () {
              setState(() {
                isPublic = true;
              });
            },
          ),
          Container(
            width: 1,
            height: 60,
            color: dominantColor.withOpacity(0.4),
          ),
          _visibilityOption(
            label: "Privat",
            icon: Icons.lock_outline_rounded,
            subtitle: "Hanya Anda",
            selected: !isPublic,
            onTap: () {
              setState(() {
                isPublic = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : submitLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          disabledBackgroundColor: secondaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: dominantColor,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: dominantColor,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Kirim Laporan",
                    style: TextStyle(
                      color: dominantColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _formSection({
    required String label,
    required Widget child,
    double bottom = 20,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(label),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 18),

              _formSection(
                label: "FOTO KERUSAKAN",
                child: _photoSection(),
                bottom: 24,
              ),

              _formSection(
                label: "JUDUL LAPORAN",
                child: TextField(
                  controller: judulController,
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                    hint: "Contoh: Jalan Rusak Parah di...",
                    icon: Icons.title_rounded,
                  ),
                ),
              ),

              _formSection(
                label: "DESKRIPSI",
                child: _descriptionField(),
                bottom: 24,
              ),

              _formSection(
                label: "ALAMAT LENGKAP",
                child: TextField(
                  controller: alamatController,
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  decoration: _inputDecoration(
                    hint: "Alamat akan terisi otomatis setelah lokasi GPS diambil",
                    icon: Icons.location_on_rounded,
                  ),
                ),
                bottom: 16,
              ),

              _formSection(
                label: "LOKASI GPS",
                child: _gpsButton(),
                bottom: 16,
              ),

              _mapPreview(),

              const SizedBox(height: 24),

              _formSection(
                label: "VISIBILITAS",
                child: _visibilitySection(),
                bottom: 32,
              ),

              _submitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}