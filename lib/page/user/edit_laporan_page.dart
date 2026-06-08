import 'package:flutter/material.dart';
import '../../service/laporanService.dart';

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

  String jenisLaporan = "public";
  bool isLoading = false;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    judulController = TextEditingController(
      text: widget.laporan["judul"] ?? "",
    );

    deskripsiController = TextEditingController(
      text: widget.laporan["deskripsi"] ?? "",
    );

    alamatController = TextEditingController(
      text: widget.laporan["alamat"] ?? "",
    );

    jenisLaporan = widget.laporan["jenis_laporan"] ?? "public";
  }

  @override
  void dispose() {
    judulController.dispose();
    deskripsiController.dispose();
    alamatController.dispose();
    super.dispose();
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
        latitude: widget.laporan["latitude"] == null
            ? null
            : double.tryParse(widget.laporan["latitude"].toString()),
        longitude: widget.laporan["longitude"] == null
            ? null
            : double.tryParse(widget.laporan["longitude"].toString()),
        alamat: alamatController.text.trim(),
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

  bool bolehDiedit() {
    final status = widget.laporan["status"]?.toString() ?? "";

    return status == "laporan_terkirim" ||
        status == "telah_dibaca" ||
        status == "laporan_telah_dibaca";
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
    if (media == null || media.toString().isEmpty) {
      return Container(
        width: double.infinity,
        height: 190,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        media.toString(),
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: dominantColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.broken_image_rounded,
              color: accentColor,
              size: 42,
            ),
          );
        },
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

            const SizedBox(height: 14),

            Container(
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
            ),

            const SizedBox(height: 24),

            if (!bolehDiedit())
              Container(
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
              ),

            const SizedBox(height: 18),

            SizedBox(
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
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}