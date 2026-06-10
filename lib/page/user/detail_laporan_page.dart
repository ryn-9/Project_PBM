import 'package:flutter/material.dart';
import 'chat_room_page.dart';
import 'edit_laporan_page.dart';

class DetailLaporanPage extends StatelessWidget {
  final int userId;
  final Map<String, dynamic> laporan;

  const DetailLaporanPage({
    super.key,
    required this.userId,
    required this.laporan,
  });

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  Color getStatusColor(String status) {
    switch (status) {
      case "laporan_terkirim":
        return Colors.orange;
      case "laporan_telah_dibaca":
      case "telah_dibaca":
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
      case "laporan_telah_dibaca":
      case "telah_dibaca":
        return "Telah Dibaca";
      case "dalam_proses_tindak_lanjut":
        return "Dalam Proses";
      case "laporan_selesai_ditindaklanjuti":
        return "Selesai";
      default:
        return status;
    }
  }

  String formatTanggal(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "-";

    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();

      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");
      final year = date.year.toString();

      return "$day/$month/$year";
    } catch (_) {
      final value = rawDate.toString();
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  bool bolehDiedit() {
    final status = laporan["status"]?.toString() ?? "";

    return status == "laporan_terkirim" ||
        status == "telah_dibaca" ||
        status == "laporan_telah_dibaca";
  }

  Widget imagePreview(dynamic media) {
    if (media == null || media.toString().isEmpty) {
      return Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          color: dominantColor.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: accentColor,
          size: 48,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        media.toString(),
        width: double.infinity,
        height: 230,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: dominantColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.broken_image_rounded,
              color: accentColor,
              size: 48,
            ),
          );
        },
      ),
    );
  }

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.15),
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
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dominantColor.withOpacity(0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: accentColor,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    final int laporanId = int.parse(laporan["id"].toString());

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    userId: userId,
                    adminId: 1,
                    referenceLaporanId: laporanId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: dominantColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text(
              "Hubungi Admin WadulGuse",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: bolehDiedit()
                ? () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditLaporanPage(
                          userId: userId,
                          laporan: laporan,
                        ),
                      ),
                    );

                    if (result == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: secondaryColor,
              side: BorderSide(
                color: bolehDiedit()
                    ? accentColor
                    : secondaryColor.withOpacity(0.25),
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              Icons.edit_note_rounded,
              color: bolehDiedit()
                  ? accentColor
                  : secondaryColor.withOpacity(0.35),
            ),
            label: Text(
              bolehDiedit() ? "Edit Laporan" : "Laporan Tidak Bisa Diedit",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final judul = laporan["judul"]?.toString() ?? "Tanpa Judul";
    final deskripsi = laporan["deskripsi"]?.toString() ?? "-";
    final alamat = laporan["alamat"]?.toString() ?? "Lokasi tidak tersedia";
    final status = laporan["status"]?.toString() ?? "-";
    final media = laporan["media"];
    final tanggal = formatTanggal(laporan["created_at"]);
    final jenisLaporan = laporan["jenis_laporan"]?.toString() ?? "-";

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          "Detail Laporan",
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imagePreview(media),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      color: secondaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                ),
                statusBadge(status),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: secondaryColor.withOpacity(0.55),
                ),
                const SizedBox(width: 5),
                Text(
                  tanggal,
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            infoCard(
              icon: Icons.description_rounded,
              title: "Deskripsi",
              value: deskripsi,
            ),
            infoCard(
              icon: Icons.location_on_rounded,
              title: "Alamat",
              value: alamat,
            ),
            infoCard(
              icon: jenisLaporan == "private"
                  ? Icons.lock_outline_rounded
                  : Icons.public_rounded,
              title: "Jenis Laporan",
              value: jenisLaporan == "private" ? "Private" : "Public",
            ),

            if (!bolehDiedit()) ...[
              const SizedBox(height: 4),
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
            ],

            const SizedBox(height: 24),
            actionButtons(context),
          ],
        ),
      ),
    );
  }
}