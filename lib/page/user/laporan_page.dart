import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'camera_capture_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../service/uploadfotoService.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController judulController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  File? imageFile;
  LatLng? _currentLatLng;
  Marker? _marker;
  String? lokasi;
  String? alamat;
  bool isPublic = true;
  bool isLoading = false;
  bool isLoadingLocation = false;

  // Color palette
  static const Color dominantColor = Color(0xFFD8C99B); // Ecru
  static const Color secondaryColor = Color(0xFF273E47); // Charcoal
  static const Color accentColor = Color(0xFFD8973C);   // Butterscotch
  static const Color bgLight = Color(0xFFF5F0E8);       // Light ecru bg
  static const Color cardBg = Color(0xFFFFFFFF);

  Future<void> pickCamera() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CameraCapturePage()),
    );
    if (imagePath != null) {
      setState(() => imageFile = File(imagePath));
    }
  }

  Future<void> getLocation() async {
    setState(() => isLoadingLocation = true);
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() => isLoadingLocation = false);
      return;
    }
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _marker = Marker(
        point: _currentLatLng!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: accentColor, size: 40),
      );
      lokasi = "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
      alamat = "Jl. Kalimantan, Sumbersari, Jember";
      isLoadingLocation = false;
    });
  }

  Future<void> submitLaporan() async {
    if (judulController.text.isEmpty ||
        descController.text.isEmpty ||
        _currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Lengkapi semua data terlebih dahulu!"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      String? mediaUrl;
      if (imageFile != null) {
        mediaUrl = await ImageKitService.uploadImage(imageFile!);
      }
      final payload = {
        "user_id": 1,
        "judul": judulController.text,
        "deskripsi": descController.text,
        "media": mediaUrl ?? "",
        "latitude": _currentLatLng!.latitude,
        "longitude": _currentLatLng!.longitude,
        "alamat": alamat ?? "",
        "jenis_laporan": isPublic ? "public" : "private",
      };
      final response = await http.post(
        Uri.parse("https://wadulguse-api.vercel.app/api/riwayat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✓ Laporan berhasil dikirim!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        judulController.clear();
        descController.clear();
        setState(() {
          imageFile = null;
          _currentLatLng = null;
          _marker = null;
          lokasi = null;
          alamat = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal: ${response.statusCode} ${response.reasonPhrase}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }

  Widget _sectionLabel(String text) => Padding(
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

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryColor.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: bgLight,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dominantColor.withOpacity(0.6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
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
                          horizontal: 10, vertical: 4),
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
                    // ── Foto Section ────────────────────────────────────
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
                                    Image.file(imageFile!, fit: BoxFit.cover),
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: secondaryColor.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit,
                                                color: dominantColor, size: 14),
                                            SizedBox(width: 4),
                                            Text("Ganti Foto",
                                                style: TextStyle(
                                                    color: dominantColor,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
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
                                    child: const Icon(Icons.camera_alt_rounded,
                                        color: accentColor, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text("Ketuk untuk ambil foto",
                                      style: TextStyle(
                                          color: secondaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text("Foto kerusakan jalan",
                                      style: TextStyle(
                                          color: secondaryColor.withOpacity(0.4),
                                          fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Judul Section ───────────────────────────────────
                    _sectionLabel("JUDUL LAPORAN"),
                    TextField(
                      controller: judulController,
                      style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      decoration: _inputDecoration(
                          "Contoh: Jalan Rusak Parah di...",
                          Icons.title_rounded),
                    ),
                    const SizedBox(height: 20),

                    // ── Deskripsi Section ───────────────────────────────
                    _sectionLabel("DESKRIPSI"),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      style: const TextStyle(color: secondaryColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            "Jelaskan kondisi kerusakan secara detail...",
                        hintStyle: TextStyle(
                            color: secondaryColor.withOpacity(0.4),
                            fontSize: 14),
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
                              color: dominantColor.withOpacity(0.6), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: accentColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Lokasi Section ──────────────────────────────────
                    _sectionLabel("LOKASI"),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoadingLocation ? null : getLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
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
                                          color: accentColor),
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
                                                  ? "Lokasi ditemukan"
                                                  : "Ambil Lokasi Saat Ini",
                                          style: TextStyle(
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
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text("Ubah",
                                          style: TextStyle(
                                              color: accentColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Alamat chip
                    if (alamat != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded,
                                color: accentColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alamat!,
                                style: const TextStyle(
                                    color: secondaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Map preview
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
                                    color: dominantColor.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: secondaryColor.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
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
                                            : []),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // ── Visibilitas Section ─────────────────────────────
                    _sectionLabel("VISIBILITAS"),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: dominantColor.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          _visibilityOption(
                              label: "Publik",
                              icon: Icons.public_rounded,
                              subtitle: "Semua dapat melihat",
                              selected: isPublic,
                              onTap: () => setState(() => isPublic = true)),
                          Container(
                              width: 1,
                              height: 60,
                              color: dominantColor.withOpacity(0.4)),
                          _visibilityOption(
                              label: "Privat",
                              icon: Icons.lock_outline_rounded,
                              subtitle: "Hanya Anda",
                              selected: !isPublic,
                              onTap: () => setState(() => isPublic = false)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit Button ───────────────────────────────────
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
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: dominantColor, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded,
                                      color: dominantColor, size: 18),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? accentColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? accentColor : secondaryColor.withOpacity(0.4),
                  size: 20),
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
                        color: selected ? secondaryColor : secondaryColor.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 10,
                          color: secondaryColor.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: accentColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}