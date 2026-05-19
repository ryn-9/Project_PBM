import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanAdminPage extends StatelessWidget {
  const LaporanAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print("STATE: ${snapshot.connectionState}");
          print("ERROR: ${snapshot.error}");
          print("JUMLAH DATA: ${snapshot.data?.docs.length}");

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
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
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String currentStatus = data['status'] ?? 'Terkirim';

              //WARNA STATUS
              Color statusColor;
              switch (currentStatus) {
                case 'Selesai':
                  statusColor = Colors.green;
                  break;
                case 'Proses':
                  statusColor = Colors.orange;
                  break;
                case 'Dibaca':
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //DATA LAPORAN
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: data['imageUrl'] != null &&
                                data['imageUrl'] != ""
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image),
                        title: Text(data['deskripsi'] ?? '-'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['lokasi'] ?? '-'),
                            const SizedBox(height: 4),
                            Text("User ID: ${data['userId'] ?? '-'}"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Status: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currentStatus,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          DropdownButton<String>(
                            value: currentStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Terkirim',
                                  child: Text('Terkirim')),
                              DropdownMenuItem(
                                  value: 'Dibaca',
                                  child: Text('Dibaca')),
                              DropdownMenuItem(
                                  value: 'Proses',
                                  child: Text('Proses')),
                              DropdownMenuItem(
                                  value: 'Selesai',
                                  child: Text('Selesai')),
                            ],
                            onChanged: (value) async {
                              if (value == null) return;

                              try {
                                // simpan messenger sebelum async
                                final messenger =
                                    ScaffoldMessenger.of(context);

                                await FirebaseFirestore.instance
                                    .collection('laporan')
                                    .doc(doc.id)
                                    .update({
                                  'status': value,
                                });

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Status berhasil diubah ke $value"),
                                  ),
                                );
                              } catch (e) {
                                final messenger =
                                    ScaffoldMessenger.of(context);

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
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