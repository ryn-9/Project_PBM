import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pbm/page/admin/admin_profil_page.dart';
import 'package:project_pbm/page/user/riwayat_user.dart';

import 'laporan_page.dart';
import 'camera_capture_page.dart';

class UserHomePage extends StatefulWidget {
  final int userId;

  const UserHomePage({
    super.key,
    required this.userId,
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
        onTap: (index) async {
          if (index == 2) {
            await openCameraFromNavbar();
            return;
          }

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
    );
  }

  Widget _buildBody() {
      switch (currentIndex) {
        case 0:
          return _dashboardContent();
  
      case 1:
          return LaporanPage(
          key: ValueKey(capturedImagePathFromNavbar ?? "laporan-manual"),
          userId: widget.userId,
          initialImagePath: capturedImagePathFromNavbar,
          onReportSubmitted: () {
            setState(() {
              capturedImagePathFromNavbar = null;
            });
          },
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('laporan')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error Firestore: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Belum ada laporan"),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            final map = data.data() as Map<String, dynamic>;

            final fotoProfil =
                map.containsKey('fotoProfil') && map['fotoProfil'] != ""
                    ? map['fotoProfil']
                    : null;

            bool isLiked = false;
            bool isDisliked = false;

            return StatefulBuilder(
              builder: (context, setStateCard) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: accentColor.withOpacity(0.5),
                    ),
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                              ),
                        title: Text(
                          map['deskripsi'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          map['status'] ?? '-',
                          style: TextStyle(
                            color: (map['status'] ?? '-') == 'Selesai'
                                ? Colors.green
                                : accentColor,
                          ),
                        ),
                      ),

                      if (map['imageUrl'] != null && map['imageUrl'] != "")
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          child: Image.network(
                            map['imageUrl'],
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: dominantColor.withOpacity(0.35),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: secondaryColor,
                                  size: 42,
                                ),
                              );
                            },
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setStateCard(() {
                                  isLiked = !isLiked;
                                  if (isLiked) isDisliked = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up,
                                    color: isLiked
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
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
                                  Icon(
                                    Icons.thumb_down,
                                    color: isDisliked
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("Dislike"),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),
                            // Komentar
                            InkWell(
                              onTap: () {
                                _showCommentSheet();
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.comment,
                                    color: Colors.grey,
                                  ),
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