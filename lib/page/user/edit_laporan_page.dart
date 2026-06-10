import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../service/laporanService.dart';
import 'camera_capture_page.dart';

class EditLaporanPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> laporan;

  const EditLaporanPage({
    super.key,
    required this.userId,
    required this.laporan,
  });

  @override
  State<EditLaporanPage> createState() => _EditLaporanPageState();
}

class _EditLaporanPageState extends State<EditLaporanPage> {
  late TextEditingController judulController;
  late TextEditingController deskripsiController;
  late TextEditingController alamatController;

  File? selectedImageFile;

  String jenisLaporan = "public";
  bool isLoading = false;
  bool isGettingLocation = false;

  double? latitude;
  double? longitude;

  final ImagePicker imagePicker = ImagePicker();

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    judulController = TextEditingController(
      text: widget.laporan["judul"]?.toString() ?? "",
    );

    deskripsiController = TextEditingController(
      text: widget.laporan["deskripsi"]?.toString() ?? "",
    );

    alamatController = TextEditingController(
      text: widget.laporan["alamat"]?.toString() ?? "",
    );

    final jenisFromApi = widget.laporan["jenis_laporan"]?.toString();

    if (jenisFromApi == "private" || jenisFromApi == "public") {
      jenisLaporan = jenisFromApi!;
    } else {
      jenisLaporan = "public";
    }

    latitude = widget.laporan["latitude"] == null
        ? null
        : double.tryParse(widget.laporan["latitude"].toString());

    longitude = widget.laporan["longitude"] == null
        ? null
        : double.tryParse(widget.laporan["longitude"].toString());
  }

  @override
  void dispose() {
    judulController.dispose();
    deskripsiController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  bool bolehDiedit() {
    final status = widget.laporan["status"]?.toString() ?? "";

    return status == "laporan_terkirim" ||
        status == "telah_dibaca" ||
        status == "laporan_telah_dibaca";
  }

  Future<void> pilihDariGaleri() async {
    if (!bolehDiedit()) return;

    final XFile? pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        selectedImageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> ambilDariKamera() async {
    if (!bolehDiedit()) return;

    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(),
      ),
    );

    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        selectedImageFile = File(imagePath);
      });
    }
  }

  void showImagePickerOptions() {
    if (!bolehDiedit()) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ganti Foto Laporan",
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: accentColor,
                  ),
                  title: const Text(
                    "Ambil dari Kamera",
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ambilDariKamera();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: accentColor,
                  ),
                  title: const Text(
                    "Pilih dari Galeri",
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pilihDariGaleri();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> ambilLokasiOtomatis() async {
    if (!bolehDiedit()) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception("GPS belum aktif");
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception("Izin lokasi ditolak");
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          "Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.",
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      String alamatBaru = "${position.latitude}, ${position.longitude}";

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ]
              .where(
                (item) => item != null && item.toString().trim().isNotEmpty,
              )
              .map((item) => item.toString())
              .toList();

          if (parts.isNotEmpty) {
            alamatBaru = parts.join(", ");
          }
        }
      } catch (_) {
        alamatBaru = "${position.latitude}, ${position.longitude}";
      }

      setState(() {
        alamatController.text = alamatBaru;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lokasi berhasil diperbarui"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengambil lokasi: $e"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  Future<void> updateLaporan() async {
    if (judulController.text.trim().isEmpty ||
        deskripsiController.text.trim().isEmpty ||
        alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul, deskripsi, dan alamat wajib diisi"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await LaporanService.updateLaporan(
        laporanId: int.parse(widget.laporan["id"].toString()),
        userId: widget.userId,
        judul: judulController.text.trim(),
        deskripsi: deskripsiController.text.trim(),
        jenisLaporan: jenisLaporan,
        latitude: latitude,
        longitude: longitude,
        alamat: alamatController.text.trim(),
        mediaFile: selectedImageFile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Laporan berhasil diperbarui"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal update laporan: $e"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "laporan_terkirim":
        return Colors.orange;
      case "telah_dibaca":
      case "laporan_telah_dibaca":
        return Colors.blue;
      case "dalam_proses_tindak_lanjut":
        return accentColor;
      case "laporan_selesai_ditindaklanjuti":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatStatus(String status) {
    switch (status) {
      case "laporan_terkirim":
        return "Laporan Terkirim";
      case "telah_dibaca":
      case "laporan_telah_dibaca":
        return "Telah Dibaca";
      case "dalam_proses_tindak_lanjut":
        return "Dalam Proses";
      case "laporan_selesai_ditindaklanjuti":
        return "Selesai";
      default:
        return status;
    }
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: TextStyle(
        color: secondaryColor.withOpacity(0.65),
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: accentColor,
        size: 20,
      ),
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: secondaryColor.withOpacity(0.12),
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

  Widget _header(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: getStatusColor(status).withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getStatusColor(status).withOpacity(0.35),
          ),
        ),
        child: Text(
          formatStatus(status),
          style: TextStyle(
            color: getStatusColor(status),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _mediaPreview(dynamic media) {
    Widget imageWidget;

    if (selectedImageFile != null) {
      imageWidget = Image.file(
        selectedImageFile!,
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
      );
    } else if (media != null && media.toString().isNotEmpty) {
      imageWidget = Image.network(
        media.toString(),
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      );
    } else {
      imageWidget = _imagePlaceholder();
    }

    return GestureDetector(
      onTap: showImagePickerOptions,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageWidget,
          ),
          if (bolehDiedit())
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: dominantColor,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Ganti Foto",
                      style: TextStyle(
                        color: dominantColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: dominantColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.45),
        ),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: accentColor,
        size: 42,
      ),
    );
  }

  Widget _locationButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed:
            isGettingLocation || !bolehDiedit() ? null : ambilLokasiOtomatis,
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(
            color: accentColor.withOpacity(0.75),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isGettingLocation
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: accentColor,
                size: 18,
              ),
        label: Text(
          isGettingLocation ? "Mengambil Lokasi..." : "Ambil Lokasi Otomatis",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _jenisLaporanDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dominantColor.withOpacity(0.8),
          width: 1.1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: jenisLaporan,
          isExpanded: true,
          iconEnabledColor: accentColor,
          dropdownColor: cardBg,
          style: const TextStyle(
            color: secondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(
              value: "public",
              child: Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text("Public"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: "private",
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text("Private"),
                ],
              ),
            ),
          ],
          onChanged: bolehDiedit()
              ? (value) {
                  if (value != null) {
                    setState(() {
                      jenisLaporan = value;
                    });
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _lockedWarning() {
    if (bolehDiedit()) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Laporan ini tidak bisa diedit karena sudah masuk proses tindak lanjut atau selesai.",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading || !bolehDiedit() ? null : updateLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          disabledBackgroundColor: secondaryColor.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: dominantColor,
                strokeWidth: 2.5,
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    color: dominantColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Simpan Perubahan",
                    style: TextStyle(
                      color: dominantColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.laporan["media"];
    final status = widget.laporan["status"]?.toString() ?? "-";

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          "Edit Laporan",
          style: TextStyle(
            color: dominantColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: secondaryColor,
        foregroundColor: dominantColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(status),
            const SizedBox(height: 16),
            _mediaPreview(media),
            const SizedBox(height: 18),

            TextField(
              controller: judulController,
              enabled: bolehDiedit(),
              style: const TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
              decoration: inputDecoration(
                label: "Judul Laporan",
                icon: Icons.title_rounded,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: deskripsiController,
              enabled: bolehDiedit(),
              maxLines: 5,
              style: const TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: inputDecoration(
                label: "Deskripsi",
                icon: Icons.description_rounded,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: alamatController,
              enabled: bolehDiedit(),
              maxLines: 2,
              style: const TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: inputDecoration(
                label: "Alamat",
                icon: Icons.location_on_rounded,
              ),
            ),

            const SizedBox(height: 10),
            _locationButton(),

            const SizedBox(height: 14),
            _jenisLaporanDropdown(),

            const SizedBox(height: 24),
            _lockedWarning(),

            const SizedBox(height: 18),
            _saveButton(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}