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
        final status = (item['status'] ?? item['status_laporan'] ?? '')
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

  String formatStatus(String status) {
    if (status == 'laporan_selesai_ditindaklanjuti') {
      return 'Selesai Ditindaklanjuti';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: FutureBuilder<List<dynamic>>(
        future: getRiwayatUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD8973C),
              ),
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

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada laporan selesai",
                style: TextStyle(
                  color: Color(0xFF273E47),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final docs = snapshot.data!;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF273E47),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8973C).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "LAPORAN SELESAI",
                        style: TextStyle(
                          color: Color(0xFFD8973C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${docs.length} laporan selesai",
                      style: const TextStyle(
                        color: Color(0xFFD8C99B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    final imageUrl = data['imageUrl'] ??
                        data['image_url'] ??
                        data['media'] ??
                        data['foto'] ??
                        data['gambar'] ??
                        '';

                    final deskripsi = data['deskripsi'] ??
                        data['description'] ??
                        data['judul'] ??
                        data['isi_laporan'] ??
                        data['laporan'] ??
                        '-';

                    final lokasi =
                        data['lokasi'] ?? data['location'] ?? data['alamat'] ?? '-';

                    final status =
                        data['status'] ?? data['status_laporan'] ?? 'Selesai';

                    final tanggal =
                        data['created_at'] ?? data['createdAt'] ?? data['tanggal'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD8973C).withOpacity(0.65),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF273E47).withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          imageUrl.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return _imagePlaceholder();
                                    },
                                  ),
                                )
                              : _imagePlaceholder(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        deskripsi.toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF273E47),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (tanggal.toString().isNotEmpty)
                                      Text(
                                        tanggal.toString().substring(0, 10),
                                        style: TextStyle(
                                          color: const Color(0xFF273E47)
                                              .withOpacity(0.55),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lokasi.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        const Color(0xFF273E47).withOpacity(0.7),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatStatus(status.toString()),
                                  style: const TextStyle(
                                    color: Color(0xFFD8973C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFD8C99B).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Color(0xFFD8973C),
      ),
    );
  }
}