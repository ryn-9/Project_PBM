import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pbm/page/admin/laporan_admin_page.dart';
import 'package:project_pbm/page/profil_page.dart';
import 'package:project_pbm/service/adminService.dart';
import '../auth/login_page.dart';
import 'package:project_pbm/widget/loading_widget.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int currentIndex = 0;

  String username = "Admin";
  String email = "-";
  String role = "admin";

  bool isLoadingUser = true;

  static const Color dominantColor = Color(0xFFD8C99B); // Ecru
  static const Color secondaryColor = Color(0xFF273E47); // Charcoal
  static const Color accentColor = Color(0xFFD8973C); // Butterscotch
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString("username") ?? "Admin";
      email = prefs.getString("email") ?? "-";
      role = prefs.getString("role") ?? "admin";
      isLoadingUser = false;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    await prefs.remove("username");
    await prefs.remove("email");
    await prefs.remove("role");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String _getTitle() {
    switch (currentIndex) {
      case 0:
        return "Dashboard Admin";
      case 1:
        return "Kelola Laporan";
      case 2:
        return "Profil Admin";
      default:
        return "Admin";
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
              color: dominantColor,
            ),
          ),
        ],
      ),
      body: isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: accentColor,
        unselectedItemColor: secondaryColor.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Laporan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (currentIndex) {
      case 0:
        return _dashboardContent();
      case 1:
        return const LaporanAdminPage();
      case 2:
        return const ProfilePage();
      default:
        return const Center(child: Text("Error"));
    }
  }

  Widget _dashboardContent() {
    if (role != "admin") {
      return const Center(
        child: Text("Akses ditolak, bukan admin"),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService.getStatistikAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          const LoadingWidget(
            message: "Memuat Dashboard...",
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Gagal mengambil statistik:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryColor,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};

        final totalLaporan = data["total_laporan"] ?? 0;
        final laporanTerkirim = data["laporan_terkirim"] ?? 0;
        final laporanTelahDibaca = data["laporan_telah_dibaca"] ?? 0;
        final dalamProses = data["dalam_proses_tindak_lanjut"] ?? 0;
        final laporanSelesai =
            data["laporan_selesai_ditindaklanjuti"] ?? 0;

        return RefreshIndicator(
          color: accentColor,
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _headerDashboard(),

              const SizedBox(height: 20),

              _bigSummaryCard(
                title: "Total Laporan",
                value: totalLaporan.toString(),
                subtitle: "Seluruh laporan yang masuk ke sistem",
                icon: Icons.assignment_rounded,
              ),

              const SizedBox(height: 16),

              _sectionLabel("RINGKASAN STATUS"),

              const SizedBox(height: 10),

              _statCard(
                title: "Laporan Terkirim",
                value: laporanTerkirim.toString(),
                icon: Icons.send_rounded,
              ),

              const SizedBox(height: 12),

              _statCard(
                title: "Laporan Telah Dibaca",
                value: laporanTelahDibaca.toString(),
                icon: Icons.mark_email_read_rounded,
              ),

              const SizedBox(height: 12),

              _statCard(
                title: "Dalam Proses Tindak Lanjut",
                value: dalamProses.toString(),
                icon: Icons.sync_rounded,
              ),

              const SizedBox(height: 12),

              _statCard(
                title: "Laporan Selesai Ditindaklanjuti",
                value: laporanSelesai.toString(),
                icon: Icons.check_circle_rounded,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        color: dominantColor,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Lihat Daftar Laporan",
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
            ],
          ),
        );
      },
    );
  }

  Widget _headerDashboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.12),
            blurRadius: 12,
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
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "WADULGUSE ADMIN",
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Hai, $username 👋",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: dominantColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Kelola dan tindak lanjuti laporan masyarakat secara terpusat.",
            style: TextStyle(
              fontSize: 13,
              color: dominantColor.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: secondaryColor,
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dominantColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}