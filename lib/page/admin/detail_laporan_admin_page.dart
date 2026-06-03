import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_pbm/service/adminService.dart';
import 'package:project_pbm/widget/loading_widget.dart';

class DetailLaporanAdminPage extends StatefulWidget {
  final Map<String, dynamic> laporan;

  const DetailLaporanAdminPage({
    super.key,
    required this.laporan,
  });

  @override
  State<DetailLaporanAdminPage> createState() => _DetailLaporanAdminPageState();
}

class _DetailLaporanAdminPageState extends State<DetailLaporanAdminPage> {
  final TextEditingController catatanController = TextEditingController();

  bool isSaving = false;
  late String selectedStatus;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  final List<String> statusList = [
    "laporan_terkirim",
    "laporan_telah_dibaca",
    "dalam_proses_tindak_lanjut",
    "laporan_selesai_ditindaklanjuti",
  ];

  @override
  void initState() {
    super.initState();

    selectedStatus = normalizeStatus(
      widget.laporan["status"]?.toString() ?? "laporan_terkirim",
    );

    catatanController.text =
        widget.laporan["catatan_admin"]?.toString() ?? "";
  }

  @override
  void dispose() {
    catatanController.dispose();
    super.dispose();
  }

  int get laporanId {
    final id = widget.laporan["id"];
    if (id is int) return id;
    return int.tryParse(id.toString()) ?? 0;
  }

  String normalizeStatus(String status) {
    final value = status.toLowerCase();

    switch (value) {
      case "laporan_terkirim":
      case "terkirim":
      case "menunggu":
        return "laporan_terkirim";

      case "laporan_telah_dibaca":
      case "dibaca":
        return "laporan_telah_dibaca";

      case "dalam_proses_tindak_lanjut":
      case "proses":
      case "tindak lanjut":
      case "dalam proses tindak lanjut":
        return "dalam_proses_tindak_lanjut";

      case "laporan_selesai_ditindaklanjuti":
      case "selesai":
        return "laporan_selesai_ditindaklanjuti";

      default:
        return "laporan_terkirim";
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case "laporan_telah_dibaca":
        return "Laporan Telah Dibaca";

      case "dalam_proses_tindak_lanjut":
        return "Dalam Proses Tindak Lanjut";

      case "laporan_selesai_ditindaklanjuti":
        return "Laporan Selesai Ditindaklanjuti";

      case "laporan_terkirim":
      default:
        return "Laporan Terkirim";
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

  String getJudul() {
    return widget.laporan["judul"]?.toString() ?? "Tanpa Judul";
  }

  String getDeskripsi() {
    return widget.laporan["deskripsi"]?.toString() ?? "Tidak ada deskripsi";
  }

  String getImageUrl() {
    return widget.laporan["media"]?.toString() ?? "";
  }

  String getAlamat() {
    return widget.laporan["alamat"]?.toString() ?? "Lokasi tidak tersedia";
  }

  String getPelapor() {
    return widget.laporan["nama_pelapor"]?.toString() ?? "Pengguna";
  }

  String getEmailPelapor() {
    return widget.laporan["email_pelapor"]?.toString() ?? "-";
  }

  String getTanggal() {
    final rawDate = widget.laporan["created_at"]?.toString();

    if (rawDate == null || rawDate.isEmpty) {
      return "-";
    }

    try {
      final date = DateTime.parse(rawDate).toLocal();

      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");
      final year = date.year.toString();

      return "$day-$month-$year";
    } catch (_) {
      return rawDate;
    }
  }

  String getJenisLaporan() {
    return widget.laporan["jenis_laporan"]?.toString() ?? "-";
  }

  double? getLatitude() {
    final value = widget.laporan["latitude"];
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  double? getLongitude() {
    final value = widget.laporan["longitude"];
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  Future<void> saveChanges() async {
    if (laporanId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ID laporan tidak valid"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await AdminService.updateStatusLaporan(
        laporanId: laporanId,
        status: selectedStatus,
        catatan: catatanController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Status laporan berhasil diperbarui"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_rounded,
                color: dominantColor,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Manajemen Status Laporan dan Catatan",
                style: TextStyle(
                  color: dominantColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: getStatusColor(selectedStatus).withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        getStatusLabel(selectedStatus),
        style: TextStyle(
          color: getStatusColor(selectedStatus),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _imageSection() {
    final imageUrl = getImageUrl();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dominantColor.withOpacity(0.6),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _emptyImage();
                },
              )
            : _emptyImage(),
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      width: double.infinity,
      height: 220,
      color: dominantColor.withOpacity(0.35),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: secondaryColor,
        size: 44,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: secondaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.75),
        ),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_rounded,
            label: "Pelapor",
            value: getPelapor(),
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.email_rounded,
            label: "Email",
            value: getEmailPelapor(),
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            label: "Tanggal",
            value: getTanggal(),
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.category_rounded,
            label: "Jenis",
            value: getJenisLaporan(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: accentColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          "$label : ",
          style: const TextStyle(
            color: secondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: secondaryColor.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapSection() {
    final lat = getLatitude();
    final lng = getLongitude();

    if (lat == null || lng == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dominantColor.withOpacity(0.6),
          ),
        ),
        child: const Text(
          "Koordinat lokasi tidak tersedia",
          style: TextStyle(color: secondaryColor),
        ),
      );
    }

    final point = LatLng(lat, lng);

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dominantColor.withOpacity(0.6),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.example.project_pbm",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 42,
                  height: 42,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: accentColor,
                    size: 42,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: InputDecoration(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dominantColor.withOpacity(0.8),
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
      items: statusList.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            getStatusLabel(status),
            style: const TextStyle(
              color: secondaryColor,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
      onChanged: isSaving
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                selectedStatus = value;
              });
            },
    );
  }

  Widget _catatanField() {
    return TextField(
      controller: catatanController,
      enabled: !isSaving,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Tambahkan catatan untuk pelapor...",
        hintStyle: TextStyle(
          color: secondaryColor.withOpacity(0.45),
          fontSize: 13,
        ),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: accentColor.withOpacity(0.75),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return const LoadingWidget(
        message: "Menyimpan perubahan laporan...",
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        getJudul(),
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusBadge(),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  "Status saat ini: ${getStatusLabel(selectedStatus)}",
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                _imageSection(),

                const SizedBox(height: 20),

                _sectionLabel("Detail Laporan"),

                Text(
                  getDeskripsi(),
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 22),

                _sectionLabel("Informasi Pelapor"),

                _infoCard(),

                const SizedBox(height: 22),

                _sectionLabel("Lokasi Laporan"),

                Text(
                  getAlamat(),
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 10),

                _mapSection(),

                const SizedBox(height: 22),

                _sectionLabel("Ubah Status Laporan"),

                _statusDropdown(),

                const SizedBox(height: 16),

                _sectionLabel("Tambahkan Catatan"),

                _catatanField(),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: dominantColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Simpan Perubahan Status Laporan",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}