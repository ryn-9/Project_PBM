import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/uploadfotoService.dart';
import 'camera_capture_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController descController = TextEditingController();

  File? imageFile;
  String? lokasi;
  LatLng? _currentLatLng;
  Marker? _marker;
  bool isPublic = true;
  bool isLoading = false;

  Future<void> pickCamera() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CameraCapturePage()),
    );

    if (imagePath != null) {
      setState(() {
        imageFile = File(imagePath);
      });
    }
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _marker = _marker = Marker(
        point: _currentLatLng!,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      );
      lokasi = "${pos.latitude}, ${pos.longitude}";
    });
  }

  Future<void> submitLaporan() async {
    if (descController.text.isEmpty || lokasi == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lengkapi data dulu!")));
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
        'status': 'Selesai',
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Laporan berhasil dikirim")));

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
          if (imageFile != null) Image.file(imageFile!, height: 150),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: pickCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ambil Foto"),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Deskripsi",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
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
          Container(
            height: 300,
            child: _currentLatLng == null
                ? const Center(child: Text("Belum ada lokasi"))
                : FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLatLng!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.project_pbm',
                    ),
                    MarkerLayer(
                      markers: _marker != null ? [_marker!] : [],
                    ),
                  ],
                )
          ),
          const SizedBox(height: 16),
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