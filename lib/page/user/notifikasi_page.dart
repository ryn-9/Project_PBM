import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotifikasiPage extends StatefulWidget {
  final int userId;

  const NotifikasiPage({
    super.key,
    required this.userId,
  });

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  Future<List<dynamic>> getNotifikasi() async {
    final response = await http.get(
      Uri.parse('https://wadulguse-api.vercel.app/api/notifikasi/${widget.userId}'),
      headers: {
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'] ?? [];
    } else {
      throw Exception('Gagal mengambil notifikasi');
    }
  }

  Future<void> tandaiDibaca(int id) async {
    await http.put(
      Uri.parse('https://wadulguse-api.vercel.app/api/notifikasi/$id/read'),
      headers: {
        'accept': '*/*',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<List<dynamic>>(
        future: getNotifikasi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryColor),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada notifikasi",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notif = data[index];

              final id = int.tryParse(notif['id'].toString()) ?? 0;
              final judul = notif['judul'] ?? 'Notifikasi';
              final pesan = notif['pesan'] ?? '-';
              final judulLaporan = notif['judul_laporan'] ?? '';
              final isRead = notif['is_read'] ?? false;

              return GestureDetector(
                onTap: () async {
                  if (id != 0) {
                    await tandaiDibaca(id);
                    setState(() {});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? dominantColor.withOpacity(0.55)
                          : accentColor.withOpacity(0.85),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isRead
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: accentColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              judul.toString(),
                              style: const TextStyle(
                                color: secondaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (judulLaporan.toString().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                judulLaporan.toString(),
                                style: const TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              pesan.toString(),
                              style: TextStyle(
                                color: secondaryColor.withOpacity(0.7),
                                fontSize: 12,
                                height: 1.35,
                              ),
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
        },
      ),
    );
  }
}