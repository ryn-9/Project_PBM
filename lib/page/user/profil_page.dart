import 'package:flutter/material.dart';
import '../../service/authService.dart';
import '../auth/login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  File? selectedImage;
  final ImagePicker picker = ImagePicker();
  bool isUploadingPhoto = false;

  bool isLoading = true;
  bool isEditing = false;

  String? fotoProfile;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void showFullPhoto() {
    if (selectedImage == null && (fotoProfile == null || fotoProfile!.isEmpty)) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // tap foto tidak nutup
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: selectedImage != null
                      ? Image.file(
                          selectedImage!,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          fotoProfile!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              color: Colors.white,
                              child: const Text("Gagal memuat gambar"),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> loadProfile() async {
    try {
      final profile = await AuthService.getProfile();

      usernameController.text = profile['nama'] ?? '';
      emailController.text = profile['email'] ?? '';
      fotoProfile = profile['foto_profile'];
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> pickGallery() async {
  final XFile? pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (pickedFile == null) return;

  final CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Sesuaikan Foto',
        toolbarColor: const Color(0xFFE7378D),
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        title: 'Sesuaikan Foto',
        aspectRatioLockEnabled: true,
      ),
    ],
  );

  if (croppedFile == null) return;

  setState(() {
    selectedImage = File(croppedFile.path);
  });

  if (!mounted) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Gunakan gambar ini sebagai foto profil?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE7378D),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              "Ya",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await uploadSelectedPhoto();
  }
}

Future<void> uploadSelectedPhoto() async {
  if (selectedImage == null) return;

  setState(() {
    isUploadingPhoto = true;
  });

  try {
    final result = await AuthService.uploadProfilePhoto(selectedImage!.path);

    final data = result["data"];

    if (!mounted) return;

    setState(() {
      fotoProfile = data?["foto_profile"];
      selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "Foto profil berhasil diperbarui"),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceAll("Exception: ", ""),
        ),
      ),
    );
  }

  if (mounted) {
    setState(() {
      isUploadingPhoto = false;
    });
  }
}

  void showPhotoOption() {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFFE7378D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(18),
      ),
    ),
    builder: (context) {
      return SizedBox(
        height: 70,
        child: ListTile(
          leading: const Icon(Icons.image, color: Colors.white),
          title: const Text(
            "Pilih dari galeri",
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            Navigator.pop(context);
            pickGallery();
          },
        ),
      );
    },
  );
}

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color(0xFFE7378D),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color(0xFFE7378D),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color(0xFFE7378D),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE7378D),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 30),

          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: showFullPhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade600,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : fotoProfile != null && fotoProfile!.isNotEmpty
                              ? NetworkImage(fotoProfile!) as ImageProvider
                              : null,
                      child: selectedImage == null &&
                              (fotoProfile == null || fotoProfile!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white,
                            )
                          : null,
                    ),

                    if (isUploadingPhoto)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: isUploadingPhoto ? null : showPhotoOption,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7378D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Username",
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: usernameController,
            enabled: isEditing,
            decoration: inputDecoration("Masukkan Username"),
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Email",
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: emailController,
            enabled: false,
            decoration: inputDecoration("Masukkan Email"),
          ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 105,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7378D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                    });
                  },
                  child: Text(
                    isEditing ? "Save" : "Edit",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              SizedBox(
                width: 105,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7378D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: logout,
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}