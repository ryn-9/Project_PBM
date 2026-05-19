import 'package:flutter/material.dart';
import 'package:project_pbm/page/user/profil_page.dart';
import '../../service/authService.dart';
import '../../service/laporanService.dart';
import '../auth/login_page.dart';
import 'laporan_page.dart';
import 'riwayat_user.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int currentIndex = 0;
  String namaUser = "User";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final profile = await AuthService.getProfile();

      if (!mounted) return;

      setState(() {
        namaUser = profile["nama"] ?? "User";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        namaUser = "User";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
        ),
      );
    }
  }

  Future<void> logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFFE7378D),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: Container(
            height: 70,
            color: const Color(0xFFE7378D),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
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
                  icon: Icon(Icons.camera),
                  label: "Kamera",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.archive_outlined),
                  label: "Riwayat",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profil",
                ),
              ],
            ),
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
        return const LaporanPage();
      case 2:
        return const Center(child: Text("Kamera"));
      case 3:
        return const Center(child: Text("Ini riwayat ya"),);
      case 4:
        return const ProfilePage();
      default:
        return const Center(child: Text("Error"));
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
      future: LaporanService.getLaporanPublic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final laporanList = snapshot.data ?? [];

        if (laporanList.isEmpty) {
          return const Center(child: Text("Belum ada laporan publik"));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "Hai, $namaUser!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              ...laporanList.map((item) {
                final data = item as Map<String, dynamic>;

                final deskripsi = _getText(data, [
                  "deskripsi",
                  "description",
                  "judul",
                ]);

                final lokasi = _getText(data, [
                  "alamat",
                  "lokasi",
                  "location",
                ]);

                final status = _getText(data, [
                  "status",
                  "status_laporan",
                ]);

                final imageUrl = _getText(data, [
                  "media",
                  "imageUrl",
                  "image_url",
                  "foto",
                  "foto_url",
                ]);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image);
                              },
                            ),
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(
                      deskripsi.isNotEmpty ? deskripsi : "-",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lokasi.isNotEmpty ? lokasi : "-"),
                        const SizedBox(height: 4),
                        Text(
                          status.isNotEmpty ? status : "-",
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "PUBLIC",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _profileContent() {
    return Center(
      child: Text(
        "Halo, $namaUser",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return "";
  }
}