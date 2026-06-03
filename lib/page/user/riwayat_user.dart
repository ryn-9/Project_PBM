import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatUserPage extends StatelessWidget {
  final int userId; // <-- tambahkan parameter userId

  const RiwayatUserPage({super.key, required this.userId}); // <-- required

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan')
            .where('userId', isEqualTo: userId) // <-- gunakan userId
            .where('status', isEqualTo: 'Selesai')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text("Error: ${snapshot.error}"),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Belum ada laporan selesai"),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: data['imageUrl'] != null && data['imageUrl'] != ""
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image);
                            },
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(data['deskripsi'] ?? '-'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['lokasi'] ?? '-'),
                      const SizedBox(height: 4),
                      Text(
                        data['status'] ?? 'Selesai',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}