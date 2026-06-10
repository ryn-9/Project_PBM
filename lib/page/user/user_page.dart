import 'package:flutter/material.dart';
import 'package:project_pbm/page/profil_page.dart';
import 'package:project_pbm/page/user/riwayat_user.dart';
import 'package:project_pbm/service/laporanService.dart';
import 'laporan_user_page.dart';
import 'camera_capture_page.dart';

class UserHomePage extends StatefulWidget {
  final int userId;
  final String token;


  const UserHomePage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int currentIndex = 0;

  String? capturedImagePathFromNavbar;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  Future<void> openCameraFromNavbar() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(),
      ),
    );

    if (!mounted) return;

    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        capturedImagePathFromNavbar = imagePath;
        currentIndex = 1;
      });
    }
  }

  final Set<int> likedReports = {};
  final Set<int> dislikedReports = {};

  late Future<List<dynamic>> publicLaporanFuture;

  @override
  void initState() {
    super.initState();
    publicLaporanFuture = LaporanService.getLaporanPublic();
  }

  Future<void> refreshPublicLaporan() async {
    setState(() {
      publicLaporanFuture = LaporanService.getLaporanPublic();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("USER ID DI USER HOME PAGE: ${widget.userId}");

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: dominantColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

Widget _buildBottomNavBar() {
  return Container(
    height: 78,
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
      ),
      boxShadow: [
        BoxShadow(
          color: secondaryColor.withOpacity(0.12),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(
          index: 0,
          icon: Icons.home_rounded,
          label: "Beranda",
        ),

        _navItem(
          index: 1,
          icon: Icons.report_rounded,
          label: "Laporan",
        ),

        _cameraNavItem(),

        _navItem(
          index: 3,
          icon: Icons.archive_outlined,
          label: "Riwayat",
        ),

        _navItem(
          index: 4,
          icon: Icons.person_rounded,
          label: "Profil",
        ),
      ],
    ),
  );
}

  Widget _navItem({
  required int index,
  required IconData icon,
  required String label,
}) {
  final bool isSelected = currentIndex == index;

  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? accentColor : secondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accentColor : secondaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _cameraNavItem() {
  return Expanded(
    child: GestureDetector(
      onTap: openCameraFromNavbar,
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 59,
              height: 59,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                border: Border.all(
                  color: cardBg,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: secondaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              "Kamera",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBody() {
    switch (currentIndex) {
      case 0:
        return _dashboardContent();

      case 1:
        return LaporanUserPage(
        userId: widget.userId,
        token: widget.token,
      );

      case 2:
        return const Center(
          child: Text("Kamera"),
        );

      case 3:
        print("USER ID DIKIRIM KE RIWAYAT: ${widget.userId}");
        return RiwayatUserPage(
          userId: widget.userId,
        );

      case 4:
        return const ProfilePage();

      default:
        return const Center(
          child: Text("Error"),
        );
    }
  }

  String _getTitle() {
    switch (currentIndex) {
      case 0:
        return "Beranda";
      case 1:
        return "Laporan";
      case 2:
        return "Kamera";
      case 3:
        return "Riwayat";
      case 4:
        return "Profil";
      default:
        return "Aplikasi";
    }
  }

  Widget _dashboardContent() {
    return FutureBuilder<List<dynamic>>(
      future: publicLaporanFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error Firestore: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingWidget("Memuat laporan publik...");
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Gagal memuat laporan:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final laporanList = snapshot.data ?? [];

        if (laporanList.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada laporan publik",
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: accentColor,
          onRefresh: refreshPublicLaporan,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: laporanList.length,
            itemBuilder: (context, index) {
              final laporan = laporanList[index] as Map<String, dynamic>;
              return _instagramReportCard(laporan);
            },
          ),
        );
      },
    );
  }

  Widget _loadingWidget(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 22,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dominantColor.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Mohon tunggu sebentar",
              style: TextStyle(
                color: secondaryColor.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instagramReportCard(Map<String, dynamic> laporan) {
    final int laporanId = int.tryParse(laporan["id"].toString()) ?? 0;

    final String judul = laporan["judul"]?.toString() ?? "Tanpa Judul";
    final String deskripsi =
        laporan["deskripsi"]?.toString() ?? "Tidak ada deskripsi";
    final String media = laporan["media"]?.toString() ?? "";
    final String status = laporan["status"]?.toString() ?? "laporan_terkirim";
    final String namaPelapor =
        laporan["nama_pelapor"]?.toString() ?? "Pengguna";
    final String fotoPelapor = laporan["foto_pelapor"]?.toString() ?? "";
    final String alamat = laporan["alamat"]?.toString() ?? "-";
    final String tanggal = formatTanggal(laporan["created_at"]?.toString());
    final String catatanAdmin = laporan["catatan_admin"]?.toString() ?? "";

    final bool isLiked = likedReports.contains(laporanId);
    final bool isDisliked = dislikedReports.contains(laporanId);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dominantColor.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _postHeader(
              namaPelapor: namaPelapor,
              fotoPelapor: fotoPelapor,
              status: status,
              tanggal: tanggal,
            ),
            _postImage(media),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isLiked) {
                          likedReports.remove(laporanId);
                        } else {
                          likedReports.add(laporanId);
                          dislikedReports.remove(laporanId);
                        }
                      });
                    },
                    child: Icon(
                      isLiked
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined,
                      color: isLiked ? accentColor : secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isDisliked) {
                          dislikedReports.remove(laporanId);
                        } else {
                          dislikedReports.add(laporanId);
                          likedReports.remove(laporanId);
                        }
                      });
                    },
                    child: Icon(
                      isDisliked
                          ? Icons.thumb_down_alt_rounded
                          : Icons.thumb_down_alt_outlined,
                      color: isDisliked ? Colors.red : secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      showKomentarBottomSheet(laporan);
                    },
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.location_on_outlined,
                    color: secondaryColor,
                    size: 24,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusLabel(status),
                      style: TextStyle(
                        color: getStatusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                judul,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: "$namaPelapor ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: deskripsi),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      alamat,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor.withOpacity(0.65),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (catatanAdmin.isNotEmpty && catatanAdmin != "null")
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          catatanAdmin,
                          style: const TextStyle(
                            color: secondaryColor,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: GestureDetector(
                onTap: () {
                  showKomentarBottomSheet(laporan);
                },
                child: Text(
                  "Lihat atau tambah komentar",
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postHeader({
    required String namaPelapor,
    required String fotoPelapor,
    required String status,
    required String tanggal,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: accentColor.withOpacity(0.16),
            backgroundImage: fotoPelapor.isNotEmpty && fotoPelapor != "null"
                ? NetworkImage(fotoPelapor)
                : null,
            child: fotoPelapor.isEmpty || fotoPelapor == "null"
                ? Text(
                    getInitial(namaPelapor),
                    style: const TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaPelapor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$tanggal • ${getStatusLabel(status)}",
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz_rounded,
            color: secondaryColor.withOpacity(0.65),
          ),
        ],
      ),
    );
  }

  Widget _postImage(String media) {
    if (media.isEmpty || media.contains("example.com")) {
      return Container(
        width: double.infinity,
        height: 250,
        color: dominantColor.withOpacity(0.28),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: secondaryColor,
            size: 46,
          ),
        ),
      );
    }

    return Image.network(
      media,
      width: double.infinity,
      height: 280,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          height: 280,
          alignment: Alignment.center,
          color: dominantColor.withOpacity(0.2),
          child: const CircularProgressIndicator(
            color: accentColor,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 250,
          alignment: Alignment.center,
          color: dominantColor.withOpacity(0.28),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: secondaryColor,
                size: 42,
              ),
              SizedBox(height: 8),
              Text(
                "Gambar gagal dimuat",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showKomentarBottomSheet(Map<String, dynamic> laporan) {
    final TextEditingController commentController = TextEditingController();

    final String catatanAdmin = laporan["catatan_admin"]?.toString() ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dominantColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Komentar",
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _commentItem(
                        name: "Admin",
                        comment: catatanAdmin.isNotEmpty &&
                                catatanAdmin != "null"
                            ? catatanAdmin
                            : "Belum ada catatan dari admin.",
                        isAdmin: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Tulis komentar...",
                          hintStyle: TextStyle(
                            color: secondaryColor.withOpacity(0.4),
                          ),
                          filled: true,
                          fillColor: bgLight,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: dominantColor.withOpacity(0.6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: accentColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final text = commentController.text.trim();

                        if (text.isEmpty) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Komentar belum tersambung ke API",
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        commentController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: secondaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _commentItem({
    required String name,
    required String comment,
    bool isAdmin = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isAdmin ? accentColor.withOpacity(0.18) : dominantColor,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person,
              color: secondaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 13,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "$name ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: comment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getInitial(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return "?";

    final parts = trimmed.split(" ");

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  String getStatusLabel(String status) {
    switch (status) {
      case "laporan_telah_dibaca":
        return "Dibaca";
      case "dalam_proses_tindak_lanjut":
        return "Diproses";
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

  String formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "-";

    try {
      final date = DateTime.parse(rawDate).toLocal();

      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");
      final year = date.year.toString();

      return "$day/$month/$year";
    } catch (_) {
      return rawDate;
    }
  }

  void _showCommentSheet() {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  "Komentar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: const [
                      ListTile(
                        leading: CircleAvatar(),
                        title: Text("User1"),
                        subtitle: Text("Komentar pertama..."),
                      ),
                      ListTile(
                        leading: CircleAvatar(),
                        title: Text("User2"),
                        subtitle: Text("Komentar kedua..."),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: "Tulis komentar...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          final comment = commentController.text.trim();

                          if (comment.isNotEmpty) {
                            print("Komentar dikirim: $comment");
                            commentController.clear();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}