import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service/uploadfotoService.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController descController = TextEditingController();

  File? imageFile;
  String? lokasi;
  bool isPublic = true;
  bool isLoading = false;
  String? status;

  final picker = ImagePicker();

  // 📷 Ambil dari kamera
  Future<void> pickCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // 🖼️ Ambil dari gallery
  Future<void> pickGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // 📍 Ambil lokasi
  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) return;

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      lokasi = "${pos.latitude}, ${pos.longitude}";
    });
  }

  // 💾 Simpan laporan
  Future<void> submitLaporan() async {
    if (descController.text.isEmpty || lokasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi data dulu!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      String? imageUrl;
        if (imageFile != null) {
          imageUrl = await ImageKitService.uploadImage(imageFile!);
        }

      await FirebaseFirestore.instance.collection('laporan').add({
        'userId': user!.uid,
        'deskripsi': descController.text,
        'lokasi': lokasi,
        'isPublic': isPublic,
        'status': 'Menunggu',
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim")),
      );

      descController.clear();
      setState(() {
        imageFile = null;
        lokasi = null;
      });

    } catch (e) {
      print(e);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Buat Laporan", style: TextStyle(fontSize: 18)),

          const SizedBox(height: 16),

          // 📷 Preview gambar
          if (imageFile != null)
            Image.file(imageFile!, height: 150),

          Row(
            children: [
              ElevatedButton(
                onPressed: pickCamera,
                child: const Text("Camera"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: pickGallery,
                child: const Text("Gallery"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 📝 Deskripsi
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Deskripsi",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // 📍 Lokasi
          Row(
            children: [
              ElevatedButton(
                onPressed: getLocation,
                child: const Text("Ambil Lokasi"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(lokasi ?? "Belum ada lokasi"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 🔒 Public / Private
          SwitchListTile(
            title: const Text("Publik"),
            value: isPublic,
            onChanged: (value) {
              setState(() {
                isPublic = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // 🚀 Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : submitLaporan,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Kirim Laporan"),
            ),
          ),
        ],
      ),
    );
  }
}