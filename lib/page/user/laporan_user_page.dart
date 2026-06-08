import 'package:flutter/material.dart';
import '../../service/laporanService.dart';
import 'tambah_laporan_page.dart';
import 'edit_laporan_page.dart';

class LaporanUserPage extends StatefulWidget {
  final int userId;
  final String token;

  const LaporanUserPage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<LaporanUserPage> createState() => _LaporanUserPageState();
}

class _LaporanUserPageState extends State<LaporanUserPage> {
  late Future<List<dynamic>> laporanFuture;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  void loadLaporan() {
    laporanFuture = LaporanService.getLaporanByUser(widget.userId);
  }

  Future<void> refreshData() async {
    setState(() {
      loadLaporan();
    });
  }

  bool isLaporanBerjalan(dynamic laporan) {
    final status = laporan["status"]?.toString() ?? "";
    return status != "laporan_selesai_ditindaklanjuti";
  }

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
    if (rawDate == null || rawDate.toString().isEmpty) return "";

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

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "LAPORAN BERJALAN",
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$total laporan sedang berjalan",
            style: const TextStyle(
              color: dominantColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pantau dan edit laporan yang belum selesai",
            style: TextStyle(
              color: dominantColor.withOpacity(0.72),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _header(0),
        const SizedBox(height: 45),
        Icon(
          Icons.assignment_outlined,
          size: 90,
          color: dominantColor.withOpacity(0.9),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Belum ada laporan berjalan",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tekan tombol tambah untuk membuat laporan baru",
          style: TextStyle(
            color: secondaryColor.withOpacity(0.6),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _errorState(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 90),
        Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red.shade300,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Gagal memuat laporan",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  Widget _laporanCard(dynamic laporan) {
    final judul = laporan["judul"] ?? "Tanpa Judul";
    final deskripsi = laporan["deskripsi"] ?? "-";
    final status = laporan["status"] ?? "-";
    final media = laporan["media"];
    final alamat = laporan["alamat"] ?? "Lokasi tidak tersedia";
    final tanggal = formatTanggal(laporan["created_at"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditLaporanPage(
                userId: widget.userId,
                laporan: Map<String, dynamic>.from(laporan),
              ),
            ),
          );

          if (result == true) {
            refreshData();
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            media != null && media.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      media.toString(),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return buildImagePlaceholder();
                      },
                    ),
                  )
                : buildImagePlaceholder(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          judul.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (tanggal.isNotEmpty)
                        Text(
                          tanggal,
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deskripsi.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.72),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: accentColor,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alamat.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(status.toString())
                              .withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          formatStatus(status.toString()),
                          style: TextStyle(
                            color: getStatusColor(status.toString()),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.edit_note_rounded,
                        color: secondaryColor.withOpacity(0.55),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: laporanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return _errorState(snapshot.error!);
            }

            final laporanList = snapshot.data ?? [];

            final laporanBerjalan = laporanList
                .where((laporan) => isLaporanBerjalan(laporan))
                .toList();

            if (laporanBerjalan.isEmpty) {
              return _emptyState();
            }

            return Column(
              children: [
                _header(laporanBerjalan.length),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: laporanBerjalan.length,
                    itemBuilder: (context, index) {
                      return _laporanCard(laporanBerjalan[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: secondaryColor,
        icon: const Icon(
          Icons.add,
          color: dominantColor,
        ),
        label: const Text(
          "Tambah Laporan",
          style: TextStyle(
            color: dominantColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TambahLaporanPage(
                userId: widget.userId,
                token: widget.token,
              ),
            ),
          );

          if (result == true) {
            refreshData();
          }
        },
      ),
    );
  }

  Widget buildImagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: dominantColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: accentColor,
      ),
    );
  }
}