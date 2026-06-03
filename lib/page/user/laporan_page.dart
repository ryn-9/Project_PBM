import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'camera_capture_page.dart';
import 'package:http_parser/http_parser.dart';


class LaporanPage extends StatefulWidget {
  final int userId; 
  const LaporanPage({super.key, required this.userId});
  
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

  Future<void> pickCamera() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CameraCapturePage()),
    );

    if (imagePath != null) {
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Izin lokasi diperlukan untuk mengambil lokasi"),
            backgroundColor: secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          alamatController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Izin lokasi ditolak permanen, silakan izinkan dari pengaturan",
            ),
            backgroundColor: secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mendapatkan lokasi: $e"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> submitLaporan() async {
  if (judulController.text.trim().isEmpty ||
      descController.text.trim().isEmpty ||
      alamatController.text.trim().isEmpty ||
      _currentLatLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Lengkapi semua data terlebih dahulu!"),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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

    request.fields["user_id"] = widget.userId.toString();
    request.fields["judul"] = judulController.text.trim();
    request.fields["deskripsi"] = descController.text.trim();
    request.fields["latitude"] = _currentLatLng!.latitude.toString();
    request.fields["longitude"] = _currentLatLng!.longitude.toString();
    request.fields["alamat"] = alamatController.text.trim();
    request.fields["jenis_laporan"] = isPublic ? "public" : "private";

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "media",
          imageFile!.path,
          contentType: MediaType("image", "jpeg"),
        ),
      );
    }

    print("POST /api/laporan");
    print("user_id: ${widget.userId}");
    print("judul: ${judulController.text.trim()}");
    print("deskripsi: ${descController.text.trim()}");
    print("latitude: ${_currentLatLng!.latitude}");
    print("longitude: ${_currentLatLng!.longitude}");
    print("alamat: ${alamatController.text.trim()}");
    print("jenis_laporan: ${isPublic ? "public" : "private"}");
    print("media ada: ${imageFile != null}");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✓ Laporan berhasil dikirim!"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal: ${response.statusCode} - ${response.body}"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    print("ERROR SUBMIT LAPORAN: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error submit laporan: $e"),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  void dispose() {
    judulController.dispose();
    descController.dispose();
    alamatController.dispose();
    super.dispose();
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
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
      fillColor: bgLight,
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
          color: dominantColor.withOpacity(0.6),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: accentColor,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: const BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
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
                      child: Text(
                        "WADULGUSE",
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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: dominantColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Laporkan kerusakan jalan di sekitar Anda",
                      style: TextStyle(
                        fontSize: 13,
                        color: dominantColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel("FOTO KERUSAKAN"),
                    GestureDetector(
                      onTap: pickCamera,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: imageFile != null ? 200 : 130,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: imageFile != null
                                ? accentColor
                                : dominantColor.withOpacity(0.5),
                            width: imageFile != null ? 2 : 1.5,
                          ),
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
                                          color:
                                              secondaryColor.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                                      color: accentColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: accentColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Ketuk untuk ambil foto",
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Foto kerusakan jalan",
                                    style: TextStyle(
                                      color: secondaryColor.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel("JUDUL LAPORAN"),
                    TextField(
                      controller: judulController,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                        "Contoh: Jalan Rusak Parah di...",
                        Icons.title_rounded,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionLabel("DESKRIPSI"),
                    TextField(
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
                        fillColor: bgLight,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: dominantColor.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel("ALAMAT LENGKAP"),
                    TextField(
                      controller: alamatController,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      decoration: _inputDecoration(
                        "Alamat akan terisi otomatis setelah lokasi GPS diambil",
                        Icons.location_on_rounded,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionLabel("LOKASI GPS"),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoadingLocation ? null : getLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _currentLatLng != null
                                    ? accentColor.withOpacity(0.1)
                                    : cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _currentLatLng != null
                                      ? accentColor
                                      : dominantColor.withOpacity(0.5),
                                  width: _currentLatLng != null ? 1.5 : 1,
                                ),
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
                                      size: 18,
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isLoadingLocation
                                              ? "Mengambil lokasi..."
                                              : _currentLatLng != null
                                                  ? "Lokasi GPS ditemukan"
                                                  : "Ambil Lokasi GPS",
                                          style: const TextStyle(
                                            color: secondaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (lokasi != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            lokasi!,
                                            style: TextStyle(
                                              color: secondaryColor
                                                  .withOpacity(0.5),
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
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: _currentLatLng == null
                          ? const SizedBox.shrink()
                          : Container(
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: dominantColor.withOpacity(0.5),
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
                                      userAgentPackageName:
                                          'com.example.project_pbm',
                                    ),
                                    MarkerLayer(
                                      markers: _marker != null
                                          ? [_marker!]
                                          : [],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel("VISIBILITAS"),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: dominantColor.withOpacity(0.5),
                          width: 1,
                        ),
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
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          disabledBackgroundColor:
                              secondaryColor.withOpacity(0.4),
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
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
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
                color: selected
                    ? accentColor
                    : secondaryColor.withOpacity(0.4),
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
                        fontWeight: FontWeight.w700,
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
}