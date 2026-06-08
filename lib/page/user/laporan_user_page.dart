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
        return Colors.blue;
      case "telah_dibaca":
        return Colors.orange;
      case "dalam_proses_tindak_lanjut":
        return Colors.purple;
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
      return "Telah Dibaca";
    case "dalam_proses_tindak_lanjut":
      return "Dalam Proses";
    case "laporan_selesai_ditindaklanjuti":
      return "Selesai";
    default:
      return status;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          "Laporan Saya",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: laporanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "Gagal memuat laporan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              );
            }

            final laporanList = snapshot.data ?? [];

            final laporanBerjalan = laporanList
                .where((laporan) => isLaporanBerjalan(laporan))
                .toList();

            if (laporanBerjalan.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.assignment_outlined,
                    size: 90,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Belum ada laporan berjalan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Tekan tombol tambah untuk membuat laporan baru",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: laporanBerjalan.length,
              itemBuilder: (context, index) {
                final laporan = laporanBerjalan[index];

                final judul = laporan["judul"] ?? "Tanpa Judul";
                final deskripsi = laporan["deskripsi"] ?? "-";
                final status = laporan["status"] ?? "-";
                final media = laporan["media"];
                final alamat = laporan["alamat"] ?? "Lokasi tidak tersedia";

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: media != null && media.toString().isNotEmpty
                                ? Image.network(
                                    media.toString(),
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return buildImagePlaceholder();
                                    },
                                  )
                                : buildImagePlaceholder(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  deskripsi.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        alamat.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status.toString())
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    formatStatus(status.toString()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: getStatusColor(status.toString()),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF273E47),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Laporan",
          style: TextStyle(color: Colors.white),
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
      width: 82,
      height: 82,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade500,
      ),
    );
  }
}