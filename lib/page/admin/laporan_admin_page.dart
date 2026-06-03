import 'package:flutter/material.dart';
import 'package:project_pbm/page/admin/detail_laporan_admin_page.dart';
import 'package:project_pbm/service/adminService.dart';
import 'package:project_pbm/widget/loading_widget.dart';

class LaporanAdminPage extends StatefulWidget {
  const LaporanAdminPage({super.key});

  @override
  State<LaporanAdminPage> createState() => _LaporanAdminPageState();
}

class _LaporanAdminPageState extends State<LaporanAdminPage> {
  late Future<List<dynamic>> laporanFuture;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  String selectedFilter = "semua";

  final List<Map<String, String>> filters = [
    {
      "label": "Semua",
      "value": "semua",
    },
    {
      "label": "Menunggu",
      "value": "laporan_terkirim",
    },
    {
      "label": "Dibaca",
      "value": "laporan_telah_dibaca",
    },
    {
      "label": "Tindak Lanjut",
      "value": "dalam_proses_tindak_lanjut",
    },
    {
      "label": "Selesai",
      "value": "laporan_selesai_ditindaklanjuti",
    },
  ];

  @override
  void initState() {
    super.initState();
    laporanFuture = AdminService.getAllLaporan();
  }

  Future<void> refreshData() async {
    setState(() {
      laporanFuture = AdminService.getAllLaporan();
    });
  }

  String getStatusLabel(String status) {
    switch (status) {
      case "laporan_telah_dibaca":
        return "Dibaca";

      case "dalam_proses_tindak_lanjut":
        return "Tindak Lanjut";

      case "laporan_selesai_ditindaklanjuti":
        return "Selesai";

      case "laporan_terkirim":
      default:
        return "Menunggu";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "laporan_telah_dibaca":
        return Colors.blue;

      case "dalam_proses_tindak_lanjut":
        return accentColor;

      case "laporan_selesai_ditindaklanjuti":
        return Colors.green;

      case "laporan_terkirim":
      default:
        return Colors.orange;
    }
  }

  List<dynamic> filteredLaporan(List<dynamic> laporan) {
    if (selectedFilter == "semua") return laporan;

    return laporan.where((item) {
      final status = item["status"]?.toString() ?? "";
      return status == selectedFilter;
    }).toList();
  }

  String getJudul(Map<String, dynamic> laporan) {
    return laporan["judul"]?.toString() ?? "Tanpa Judul";
  }

  String getDeskripsi(Map<String, dynamic> laporan) {
    return laporan["deskripsi"]?.toString() ?? "Tidak ada deskripsi";
  }

  String getImageUrl(Map<String, dynamic> laporan) {
    return laporan["media"]?.toString() ?? "";
  }

  String getAlamat(Map<String, dynamic> laporan) {
    return laporan["alamat"]?.toString() ?? "Lokasi tidak tersedia";
  }

  String getStatus(Map<String, dynamic> laporan) {
    return laporan["status"]?.toString() ?? "laporan_terkirim";
  }

  Widget _filterChip(Map<String, String> filter) {
    final label = filter["label"]!;
    final value = filter["value"]!;
    final bool isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : dominantColor,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: secondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(24),
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
              "MANAJEMEN LAPORAN",
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
            "Daftar Laporan",
            style: TextStyle(
              color: dominantColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Total $total laporan masuk dari masyarakat",
            style: TextStyle(
              color: dominantColor.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      width: 120,
      height: 125,
      color: dominantColor.withOpacity(0.35),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: secondaryColor,
        size: 36,
      ),
    );
  }

  Widget _laporanCard(Map<String, dynamic> laporan) {
    final id = laporan["id"];
    final judul = getJudul(laporan);
    final deskripsi = getDeskripsi(laporan);
    final alamat = getAlamat(laporan);
    final imageUrl = getImageUrl(laporan);
    final status = getStatus(laporan);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLaporanAdminPage(
              laporan: laporan,
            ),
          ),
        );

        refreshData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withOpacity(0.9),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(17),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 120,
                      height: 125,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _emptyImage();
                      },
                    )
                  : _emptyImage(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deskripsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor.withOpacity(0.65),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alamat,
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
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            getStatusLabel(status),
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text(
                          "Detail Laporan",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (id != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "#$id",
                        style: TextStyle(
                          color: secondaryColor.withOpacity(0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<List<dynamic>>(
        future: laporanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(
              message: "Memuat daftar laporan...",
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Gagal mengambil laporan:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: secondaryColor),
                ),
              ),
            );
          }

          final laporan = snapshot.data ?? [];
          final filtered = filteredLaporan(laporan);

          if (laporan.isEmpty) {
            return _emptyState("Belum ada laporan");
          }

          return RefreshIndicator(
            color: accentColor,
            onRefresh: refreshData,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _header(laporan.length),
                const SizedBox(height: 18),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map(_filterChip).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  _emptyState("Tidak ada laporan pada filter ini")
                else
                  ...filtered.map((item) {
                    return _laporanCard(item as Map<String, dynamic>);
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}