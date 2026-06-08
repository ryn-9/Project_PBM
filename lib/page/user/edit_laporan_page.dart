import 'package:flutter/material.dart';
import '../../service/laporanService.dart';

class EditLaporanPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> laporan;

  const EditLaporanPage({
    super.key,
    required this.userId,
    required this.laporan,
  });

  @override
  State<EditLaporanPage> createState() => _EditLaporanPageState();
}

class _EditLaporanPageState extends State<EditLaporanPage> {
  late TextEditingController judulController;
  late TextEditingController deskripsiController;
  late TextEditingController alamatController;

  String jenisLaporan = "public";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    judulController = TextEditingController(
      text: widget.laporan["judul"] ?? "",
    );

    deskripsiController = TextEditingController(
      text: widget.laporan["deskripsi"] ?? "",
    );

    alamatController = TextEditingController(
      text: widget.laporan["alamat"] ?? "",
    );

    jenisLaporan = widget.laporan["jenis_laporan"] ?? "public";
  }

  @override
  void dispose() {
    judulController.dispose();
    deskripsiController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  Future<void> updateLaporan() async {
    if (judulController.text.trim().isEmpty ||
        deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul dan deskripsi wajib diisi"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await LaporanService.updateLaporan(
        laporanId: int.parse(widget.laporan["id"].toString()),
        userId: widget.userId,
        judul: judulController.text.trim(),
        deskripsi: deskripsiController.text.trim(),
        jenisLaporan: jenisLaporan,
        latitude: widget.laporan["latitude"] == null
            ? null
            : double.tryParse(widget.laporan["latitude"].toString()),
        longitude: widget.laporan["longitude"] == null
            ? null
            : double.tryParse(widget.laporan["longitude"].toString()),
        alamat: alamatController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Laporan berhasil diperbarui"),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal update laporan: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool bolehDiedit() {
    final status = widget.laporan["status"]?.toString() ?? "";

    return status == "laporan_terkirim" || status == "telah_dibaca";
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.laporan["media"];
    final status = widget.laporan["status"] ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          "Edit Laporan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (media != null && media.toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  media,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Status laporan: $status",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: judulController,
              enabled: bolehDiedit(),
              decoration: InputDecoration(
                labelText: "Judul Laporan",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: deskripsiController,
              enabled: bolehDiedit(),
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: alamatController,
              enabled: bolehDiedit(),
              decoration: InputDecoration(
                labelText: "Alamat",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: jenisLaporan,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: "public",
                      child: Text("Public"),
                    ),
                    DropdownMenuItem(
                      value: "private",
                      child: Text("Private"),
                    ),
                  ],
                  onChanged: bolehDiedit()
                      ? (value) {
                          if (value != null) {
                            setState(() {
                              jenisLaporan = value;
                            });
                          }
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (!bolehDiedit())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Laporan ini tidak bisa diedit karena sudah masuk proses tindak lanjut atau selesai.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isLoading || !bolehDiedit() ? null : updateLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}