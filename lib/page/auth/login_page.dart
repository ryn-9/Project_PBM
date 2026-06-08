import 'dart:convert';

import 'package:flutter/material.dart';
import 'register_page.dart';
import '../user/user_page.dart';
import '../admin/admin_page.dart';
import '../../service/authService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Color(0xFFFFFFFF);

  Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');

    if (parts.length != 3) {
      throw Exception("Format token tidak valid");
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));

    return jsonDecode(decoded);
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Email & password tidak boleh kosong"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("LOGIN RESPONSE: $data");

      final token = data["token"];

      if (token == null) {
        throw Exception("Token tidak ditemukan dari response login");
      }

      final tokenPayload = decodeJwtPayload(token);

      print("TOKEN PAYLOAD: $tokenPayload");

      final dynamic rawUserId = tokenPayload["id"];

      if (rawUserId == null) {
        throw Exception("User ID tidak ditemukan di dalam token");
      }

      final int userId =
          rawUserId is int ? rawUserId : int.parse(rawUserId.toString());

      final String role = tokenPayload["role"]?.toString() ??
          data["role"]?.toString() ??
          "user";

      if (!mounted) return;

      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminHomePage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserHomePage(userId: userId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: secondaryColor.withOpacity(0.55),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: accentColor,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: bgLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: dominantColor.withOpacity(0.7),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: accentColor,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _circleDecoration({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            left: -80,
            child: _circleDecoration(
              size: 220,
              color: dominantColor.withOpacity(0.55),
            ),
          ),
          Positioned(
            top: 70,
            right: -45,
            child: _circleDecoration(
              size: 120,
              color: accentColor.withOpacity(0.25),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -110,
            child: _circleDecoration(
              size: 280,
              color: secondaryColor.withOpacity(0.12),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    Column(
                      children: [
                        const Text(
                          "WADUL GUSE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.8,
                          ),
                        ),

                        // const SizedBox(height: 3),

                        const Text(
                          "Masuk",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: dominantColor.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LOGIN AKUN",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: secondaryColor,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              label: "Email",
                              icon: Icons.email_rounded,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            style: const TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              label: "Password",
                              icon: Icons.lock_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: accentColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                disabledBackgroundColor:
                                    secondaryColor.withOpacity(0.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: dominantColor,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login_rounded,
                                          color: dominantColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Login",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: dominantColor,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Belum punya akun? ",
                                  style: TextStyle(
                                    color: secondaryColor.withOpacity(0.55),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Daftar",
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}