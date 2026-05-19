import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pbm/page/user/riwayat_user.dart';
import '../auth/login_page.dart';
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
          ),
        ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laporan')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error Firestore: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Belum ada laporan"));
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index];

            final fotoProfil = (data.data() as Map<String, dynamic>)
                    .containsKey('fotoProfil') &&
                data['fotoProfil'] != ""
                ? data['fotoProfil']
                : null;

            bool isLiked = false;
            bool isDisliked = false;

            return StatefulBuilder(
              builder: (context, setStateCard) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.pink),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: fotoProfil != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  fotoProfil,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, size: 50),
                        title: Text(
                          data['deskripsi'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data['status'] ?? '-',
                          style: TextStyle(
                            color: (data['status'] ?? '-') == 'Selesai'
                                ? Colors.green
                                : Colors.pink,
                          ),
                        ),
                      ),
                      if (data['imageUrl'] != null && data['imageUrl'] != "")
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12)),
                          child: Image.network(
                            data['imageUrl'],
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          "PUBLIC",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Like
                            InkWell(
                              onTap: () {
                                setStateCard(() {
                                  isLiked = !isLiked;
                                  if (isLiked) isDisliked = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      color:
                                          isLiked ? Colors.blue : Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text("Like"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Dislike
                            InkWell(
                              onTap: () {
                                setStateCard(() {
                                  isDisliked = !isDisliked;
                                  if (isDisliked) isLiked = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_down,
                                      color:
                                          isDisliked ? Colors.red : Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text("Dislike"),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Komentar
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (context) {
                                    TextEditingController commentController =
                                        TextEditingController();
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom),
                                      child: SizedBox(
                                        height: 400,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Container(
                                                width: 40,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[400],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              "Komentar",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            const Divider(),
                                            Expanded(
                                              child: ListView(
                                                children: const [
                                                  ListTile(
                                                    leading: CircleAvatar(),
                                                    title: Text("User1"),
                                                    subtitle: Text(
                                                        "Komentar pertama..."),
                                                  ),
                                                  ListTile(
                                                    leading: CircleAvatar(),
                                                    title: Text("User2"),
                                                    subtitle: Text(
                                                        "Komentar kedua..."),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          commentController,
                                                      decoration:
                                                          const InputDecoration(
                                                        hintText:
                                                            "Tulis komentar...",
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius.circular(
                                                                      20)),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                                horizontal: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.send,
                                                        color: Colors.blue),
                                                    onPressed: () {
                                                      String comment =
                                                          commentController.text
                                                              .trim();
                                                      if (comment.isNotEmpty) {
                                                        print(
                                                            "Komentar dikirim: $comment");
                                                        commentController.clear();
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.comment, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text("Komentar"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}