import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiwayatUserPage extends StatelessWidget {
  final int userId;

  const RiwayatUserPage({super.key, required this.userId});

  Future<List<dynamic>> getRiwayatUser() async {
    final response = await http.get(
      Uri.parse(
        'https://wadulguse-api.vercel.app/api/laporan/user/$userId',
      ),
      headers: {
        'accept': '*/*',
      },
    );

    print("USER ID RIWAYAT: $userId");
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final List data = result['data'] ?? [];

      return data.where((item) {
        final status = (item['status'] ??
                item['status_laporan'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

        print("STATUS ITEM: $status");

        return status == 'selesai' ||
            status == 'laporan_selesai_ditindaklanjuti';
      }).toList();
    } else {
      throw Exception('Gagal mengambil data laporan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FD),
      body: FutureBuilder<List<dynamic>>(
        future: getRiwayatUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada laporan selesai",
              ),
            );
          }

          final docs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              final imageUrl =
                  data['imageUrl'] ??
                  data['image_url'] ??
                  data['media'] ??
                  data['foto'] ??
                  data['gambar'] ??
                  '';

              final deskripsi =
                  data['deskripsi'] ??
                  data['description'] ??
                  data['judul'] ??
                  data['isi_laporan'] ??
                  data['laporan'] ??
                  '-';

              final lokasi =
                  data['lokasi'] ??
                  data['location'] ??
                  data['alamat'] ??
                  '-';

              final status =
                  data['status'] ??
                  data['status_laporan'] ??
                  'Selesai';

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading:
                      imageUrl
                              .toString()
                              .isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      8),
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons
                                        .broken_image,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons
                                  .image_not_supported,
                            ),
                  title: Text(
                    deskripsi.toString(),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        lokasi.toString(),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        status.toString(),
                        style:
                            const TextStyle(
                              color:
                                  Colors.green,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
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