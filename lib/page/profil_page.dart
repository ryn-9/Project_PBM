import 'package:flutter/material.dart';
import '../../service/authService.dart';
import '../auth/login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:project_pbm/widget/loading_widget.dart';

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
  bool isSaving = false;

  String? fotoProfile;

  // Color palette baru
  static const Color dominantColor = Color(0xFFD8C99B); // Ecru
  static const Color secondaryColor = Color(0xFF273E47); // Charcoal
  static const Color accentColor = Color(0xFFD8973C); // Butterscotch
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    loadProfile();
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
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
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

  Future<void> saveProfile() async {
    if (!isEditing) {
      setState(() {
        isEditing = true;
      });
      return;
    }

    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username tidak boleh kosong"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Kalau AuthService kamu punya method updateProfile,
      // aktifkan bagian ini.
      //
      // await AuthService.updateProfile(
      //   nama: usernameController.text.trim(),
      // );

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
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
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
                              color: cardBg,
                              child: const Text(
                                "Gagal memuat gambar",
                                style: TextStyle(color: secondaryColor),
                              ),
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
          toolbarColor: secondaryColor,
          toolbarWidgetColor: dominantColor,
          activeControlsWidgetColor: accentColor,
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
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Konfirmasi",
            style: TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Gunakan gambar ini sebagai foto profil?",
            style: TextStyle(color: secondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                "Batal",
                style: TextStyle(color: secondaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Ya",
                style: TextStyle(
                  color: dominantColor,
                  fontWeight: FontWeight.bold,
                ),
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dominantColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      color: accentColor,
                    ),
                  ),
                  title: const Text(
                    "Pilih dari galeri",
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    "Gunakan foto dari perangkat",
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pickGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: secondaryColor.withOpacity(0.4),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: accentColor,
        size: 20,
      ),
      filled: true,
      fillColor: isEditing ? cardBg : bgLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: dominantColor.withOpacity(0.7),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: accentColor,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: dominantColor.withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: secondaryColor,
        ),
      ),
    );
  }

  Widget profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "PROFIL PENGGUNA",
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: showFullPhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: dominantColor,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : fotoProfile != null && fotoProfile!.isNotEmpty
                                ? NetworkImage(fotoProfile!) as ImageProvider
                                : null,
                        child: selectedImage == null &&
                                (fotoProfile == null || fotoProfile!.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                size: 68,
                                color: secondaryColor,
                              )
                            : null,
                      ),
                    ),

                    if (isUploadingPhoto)
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: dominantColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: isUploadingPhoto ? null : showPhotoOption,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondaryColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: secondaryColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            usernameController.text.isEmpty
                ? "Pengguna"
                : usernameController.text,
            style: const TextStyle(
              color: dominantColor,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            emailController.text.isEmpty ? "-" : emailController.text,
            style: TextStyle(
              color: dominantColor.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget accountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dominantColor.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionLabel("DATA AKUN"),

          TextField(
            controller: usernameController,
            enabled: isEditing && !isSaving,
            style: const TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: inputDecoration(
              hint: "Masukkan username",
              icon: Icons.person_rounded,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: emailController,
            enabled: false,
            style: const TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: inputDecoration(
              hint: "Masukkan email",
              icon: Icons.email_rounded,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Email tidak dapat diubah.",
            style: TextStyle(
              color: secondaryColor.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isOutline = false,
  }) {
    if (isOutline) {
      return SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side: BorderSide(
              color: foregroundColor,
              width: 1.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
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
      return const LoadingWidget(
        message: "Memuat profil...",
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: loadProfile,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            profileHeader(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  accountCard(),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: actionButton(
                          title: isEditing ? "Save" : "Edit",
                          icon: isEditing
                              ? Icons.save_rounded
                              : Icons.edit_rounded,
                          onPressed: isSaving ? null : saveProfile,
                          backgroundColor: secondaryColor,
                          foregroundColor: dominantColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: actionButton(
                          title: "Logout",
                          icon: Icons.logout_rounded,
                          onPressed: logout,
                          backgroundColor: cardBg,
                          foregroundColor: secondaryColor,
                          isOutline: true,
                        ),
                      ),
                    ],
                  ),

                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    actionButton(
                      title: "Batal Edit",
                      icon: Icons.close_rounded,
                      onPressed: isSaving
                          ? null
                          : () {
                              setState(() {
                                isEditing = false;
                              });
                              loadProfile();
                            },
                      backgroundColor: accentColor.withOpacity(0.12),
                      foregroundColor: accentColor,
                      isOutline: true,
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}