import 'package:flutter/material.dart';
import 'package:project_pbm/page/profil_page.dart';
import 'package:project_pbm/page/user/riwayat_user.dart';
import 'package:project_pbm/service/laporanService.dart';
import 'package:project_pbm/service/reactionService.dart';
import 'package:project_pbm/service/komentarService.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    debugPrint("USER ID DI USER HOME PAGE: ${widget.userId}");

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
                color:
                    isSelected ? accentColor : secondaryColor.withOpacity(0.5),
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
        debugPrint("USER ID DIKIRIM KE RIWAYAT: ${widget.userId}");
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
                  ReactionBar(
                    userId: widget.userId,
                    laporanId: laporanId,
                    token: widget.token,
                    accentColor: accentColor,
                    secondaryColor: secondaryColor,
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
    final int laporanId = int.tryParse(laporan["id"].toString()) ?? 0;

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
        return KomentarBottomSheet(
          laporanId: laporanId,
          userId: widget.userId,
          token: widget.token,
          bgLight: bgLight,
          cardBg: cardBg,
          dominantColor: dominantColor,
          secondaryColor: secondaryColor,
          accentColor: accentColor,
        );
      },
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
}

class ReactionBar extends StatefulWidget {
  final int userId;
  final int laporanId;
  final String token;
  final Color accentColor;
  final Color secondaryColor;

  const ReactionBar({
    super.key,
    required this.userId,
    required this.laporanId,
    required this.token,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  int? likeCount;
  int? dislikeCount;
  String? myReaction;

  bool isLoading = true;
  bool isReacting = false;

  String get localReactionKey =>
      "reaction_${widget.userId}_${widget.laporanId}";

  @override
  void initState() {
    super.initState();
    loadReaction();
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<String?> getLocalReaction() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(localReactionKey);

    if (value == null || value.isEmpty || value == "null") {
      return null;
    }

    return value;
  }

  Future<void> saveLocalReaction(String? reaction) async {
    final prefs = await SharedPreferences.getInstance();

    if (reaction == null) {
      await prefs.remove(localReactionKey);
    } else {
      await prefs.setString(localReactionKey, reaction);
    }
  }

  String? normalizeReaction(dynamic value) {
    if (value == null) return null;

    final text = value.toString().toLowerCase();

    if (text == "like" || text == "liked") return "like";
    if (text == "dislike" || text == "disliked") return "dislike";

    return null;
  }

  Future<void> loadReaction() async {
    try {
      final localReaction = await getLocalReaction();

      if (mounted) {
        setState(() {
          myReaction = localReaction;
        });
      }

      final data = await ReactionService.getReactionCount(
        laporanId: widget.laporanId,
        token: widget.token,
      );

      if (!mounted) return;

      final apiReaction = normalizeReaction(
        data["my_reaction"] ??
            data["user_reaction"] ??
            data["reaction"] ??
            data["type"],
      );

      setState(() {
        likeCount = toInt(
          data["like_count"] ??
              data["likes"] ??
              data["total_like"] ??
              data["total_likes"] ??
              data["jumlah_like"],
        );

        dislikeCount = toInt(
          data["dislike_count"] ??
              data["dislikes"] ??
              data["total_dislike"] ??
              data["total_dislikes"] ??
              data["jumlah_dislike"],
        );

        myReaction = apiReaction ?? localReaction;
        isLoading = false;
      });

      if (apiReaction != null) {
        await saveLocalReaction(apiReaction);
      }
    } catch (e) {
      if (!mounted) return;

      final localReaction = await getLocalReaction();

      setState(() {
        myReaction = localReaction;
        isLoading = false;
      });
    }
  }

  Future<void> toggleLike() async {
    if (isReacting) return;

    final previousReaction = myReaction;
    final previousLikeCount = likeCount;
    final previousDislikeCount = dislikeCount;

    String? nextReaction;
    int nextLikeCount = likeCount ?? 0;
    int nextDislikeCount = dislikeCount ?? 0;

    if (myReaction == "like") {
      nextReaction = null;
      if (nextLikeCount > 0) nextLikeCount--;
    } else if (myReaction == "dislike") {
      nextReaction = "like";
      if (nextDislikeCount > 0) nextDislikeCount--;
      nextLikeCount++;
    } else {
      nextReaction = "like";
      nextLikeCount++;
    }

    setState(() {
      isReacting = true;
      myReaction = nextReaction;
      likeCount = nextLikeCount;
      dislikeCount = nextDislikeCount;
    });

    await saveLocalReaction(nextReaction);

    try {
      if (nextReaction == null) {
        await ReactionService.deleteReaction(
          laporanId: widget.laporanId,
          token: widget.token,
        );
      } else {
        await ReactionService.likeLaporan(
          laporanId: widget.laporanId,
          token: widget.token,
        );
      }
    } catch (e) {
      await saveLocalReaction(previousReaction);

      if (!mounted) return;

      setState(() {
        myReaction = previousReaction;
        likeCount = previousLikeCount;
        dislikeCount = previousDislikeCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengubah reaction: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isReacting = false;
        });
      }
    }
  }

  Future<void> toggleDislike() async {
    if (isReacting) return;

    final previousReaction = myReaction;
    final previousLikeCount = likeCount;
    final previousDislikeCount = dislikeCount;

    String? nextReaction;
    int nextLikeCount = likeCount ?? 0;
    int nextDislikeCount = dislikeCount ?? 0;

    if (myReaction == "dislike") {
      nextReaction = null;
      if (nextDislikeCount > 0) nextDislikeCount--;
    } else if (myReaction == "like") {
      nextReaction = "dislike";
      if (nextLikeCount > 0) nextLikeCount--;
      nextDislikeCount++;
    } else {
      nextReaction = "dislike";
      nextDislikeCount++;
    }

    setState(() {
      isReacting = true;
      myReaction = nextReaction;
      likeCount = nextLikeCount;
      dislikeCount = nextDislikeCount;
    });

    await saveLocalReaction(nextReaction);

    try {
      if (nextReaction == null) {
        await ReactionService.deleteReaction(
          laporanId: widget.laporanId,
          token: widget.token,
        );
      } else {
        await ReactionService.dislikeLaporan(
          laporanId: widget.laporanId,
          token: widget.token,
        );
      }
    } catch (e) {
      await saveLocalReaction(previousReaction);

      if (!mounted) return;

      setState(() {
        myReaction = previousReaction;
        likeCount = previousLikeCount;
        dislikeCount = previousDislikeCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengubah reaction: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isReacting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = myReaction == "like";
    final bool isDisliked = myReaction == "dislike";

    return Row(
      children: [
        GestureDetector(
          onTap: isLoading || isReacting ? null : toggleLike,
          child: Row(
            children: [
              Icon(
                isLiked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                color: isLiked ? widget.accentColor : widget.secondaryColor,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                likeCount?.toString() ?? "...",
                style: TextStyle(
                  color: isLiked ? widget.accentColor : widget.secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: isLoading || isReacting ? null : toggleDislike,
          child: Row(
            children: [
              Icon(
                isDisliked
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                color: isDisliked ? Colors.red : widget.secondaryColor,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                dislikeCount?.toString() ?? "...",
                style: TextStyle(
                  color: isDisliked ? Colors.red : widget.secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KomentarBottomSheet extends StatefulWidget {
  final int laporanId;
  final int userId;
  final String token;

  final Color bgLight;
  final Color cardBg;
  final Color dominantColor;
  final Color secondaryColor;
  final Color accentColor;

  const KomentarBottomSheet({
    super.key,
    required this.laporanId,
    required this.userId,
    required this.token,
    required this.bgLight,
    required this.cardBg,
    required this.dominantColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  State<KomentarBottomSheet> createState() => _KomentarBottomSheetState();
}

class _KomentarBottomSheetState extends State<KomentarBottomSheet> {
  final TextEditingController commentController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;

  List<dynamic> komentarList = [];

  @override
  void initState() {
    super.initState();
    loadKomentar();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> loadKomentar() async {
    try {
      final data = await KomentarService.getKomentarByLaporan(widget.laporanId);

      if (!mounted) return;

      setState(() {
        komentarList = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat komentar: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> tambahKomentar() async {
    final text = commentController.text.trim();

    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      final newKomentar = await KomentarService.tambahKomentar(
        laporanId: widget.laporanId,
        userId: widget.userId,
        komentar: text,
        token: widget.token,
      );

      commentController.clear();

      setState(() {
        komentarList.add(newKomentar);
      });

      await loadKomentar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambahkan komentar: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> editKomentar(dynamic komentar) async {
    final int komentarId = toInt(komentar["id"]);

    final String komentarLama = komentar["komentar"]?.toString() ??
        komentar["isi_komentar"]?.toString() ??
        komentar["isi"]?.toString() ??
        "";

    final TextEditingController editController =
        TextEditingController(text: komentarLama);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardBg,
          title: const Text("Edit Komentar"),
          content: TextField(
            controller: editController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Tulis komentar...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, editController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: widget.secondaryColor,
              ),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    editController.dispose();

    if (result == null || result.isEmpty) return;

    try {
      final updatedKomentar = await KomentarService.editKomentar(
        komentarId: komentarId,
        komentar: result,
        token: widget.token,
      );

      setState(() {
        final index = komentarList.indexWhere(
          (item) => toInt(item["id"]) == komentarId,
        );

        if (index != -1) {
          komentarList[index] = {
            ...Map<String, dynamic>.from(komentarList[index]),
            ...updatedKomentar,
            "komentar": result,
          };
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal edit komentar: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> hapusKomentar(dynamic komentar) async {
    final int komentarId = toInt(komentar["id"]);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Komentar"),
          content: const Text("Yakin ingin menghapus komentar ini?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await KomentarService.hapusKomentar(
        komentarId: komentarId,
        token: widget.token,
      );

      setState(() {
        komentarList.removeWhere(
          (item) => toInt(item["id"]) == komentarId,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal hapus komentar: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool isKomentarMilikSendiri(dynamic komentar) {
    final int komentarUserId = toInt(
      komentar["user_id"] ?? komentar["id_user"] ?? komentar["pelapor_id"],
    );

    return komentarUserId == widget.userId;
  }

  String getNamaKomentator(dynamic komentar) {
    return komentar["nama"]?.toString() ??
        komentar["nama_user"]?.toString() ??
        komentar["username"]?.toString() ??
        komentar["nama_pelapor"]?.toString() ??
        komentar["user"]?["nama"]?.toString() ??
        "User ${komentar["user_id"] ?? ""}";
  }

  String getFotoKomentator(dynamic komentar) {
    return komentar["foto_profile"]?.toString() ??
        komentar["foto_pelapor"]?.toString() ??
        komentar["foto_user"]?.toString() ??
        komentar["user"]?["foto_profile"]?.toString() ??
        "";
  }

  String getIsiKomentar(dynamic komentar) {
    return komentar["komentar"]?.toString() ??
        komentar["isi_komentar"]?.toString() ??
        komentar["isi"]?.toString() ??
        "-";
  }

  String getTanggal(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "";

    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();

      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, "0");
      final minute = date.minute.toString().padLeft(2, "0");

      return "$day/$month/$year $hour:$minute";
    } catch (_) {
      return rawDate.toString();
    }
  }

  Widget komentarItem(dynamic komentar) {
    final bool isMine = isKomentarMilikSendiri(komentar);
    final String nama = getNamaKomentator(komentar);
    final String foto = getFotoKomentator(komentar);
    final String isi = getIsiKomentar(komentar);
    final String tanggal = getTanggal(komentar["created_at"]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isMine ? widget.accentColor.withOpacity(0.2) : widget.dominantColor,
            backgroundImage:
                foto.isNotEmpty && foto != "null" ? NetworkImage(foto) : null,
            child: foto.isEmpty || foto == "null"
                ? Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : "?",
                    style: TextStyle(
                      color: widget.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: widget.bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.dominantColor.withOpacity(0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMine ? "$nama (Saya)" : nama,
                          style: TextStyle(
                            color: widget.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isMine)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: widget.secondaryColor,
                          ),
                          onSelected: (value) {
                            if (value == "edit") {
                              editKomentar(komentar);
                            } else if (value == "hapus") {
                              hapusKomentar(komentar);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "edit",
                              child: Text("Edit"),
                            ),
                            PopupMenuItem(
                              value: "hapus",
                              child: Text("Hapus"),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isi,
                    style: TextStyle(
                      color: widget.secondaryColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (tanggal.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      tanggal,
                      style: TextStyle(
                        color: widget.secondaryColor.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget komentarListWidget() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (komentarList.isEmpty) {
      return Center(
        child: Text(
          "Belum ada komentar",
          style: TextStyle(
            color: widget.secondaryColor.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: widget.accentColor,
      onRefresh: loadKomentar,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6),
        itemCount: komentarList.length,
        itemBuilder: (context, index) {
          return komentarItem(komentarList[index]);
        },
      ),
    );
  }

  Widget inputKomentar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: commentController,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Tulis komentar...",
              hintStyle: TextStyle(
                color: widget.secondaryColor.withOpacity(0.4),
              ),
              filled: true,
              fillColor: widget.bgLight,
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
                  color: widget.dominantColor.withOpacity(0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: widget.accentColor,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isSending ? null : tambahKomentar,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSending
                  ? widget.secondaryColor.withOpacity(0.35)
                  : widget.accentColor,
              shape: BoxShape.circle,
            ),
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: widget.secondaryColor,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: widget.dominantColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Komentar",
              style: TextStyle(
                color: widget.secondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: komentarListWidget(),
            ),
            const SizedBox(height: 10),
            inputKomentar(),
          ],
        ),
      ),
    );
  }
}