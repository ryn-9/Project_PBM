import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pbm/riwayat_user.dart';
import 'login_page.dart';
import 'laporan_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

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
          ),),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: _buildBody(),

      // 🔥 FIX ADA DI SINI
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: Container(
            height: 70, //bikin navbar lebih tinggi
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
        return const RiwayatUserPage();
      case 4:
        return const Center(child: Text("Halaman Profil"));
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!;
        String username = data['username'] ?? 'User';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hai, $username!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              _statCard("Laporan yang perlu ditindaklanjuti", "120"),
              const SizedBox(height: 12),
              _statCard("Laporan yang sedang dalam proses ditindaklanjuti", "130"),
              const SizedBox(height: 12),
              _statCard("Laporan yang sudah ditindaklanjuti", "60"),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7378D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Placeholder()),
                    );
                  },
                  child: const Text(
                    "Daftar Laporan",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7378D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE7378D),
            ),
          ),
        ],
      ),
    );
  }
}