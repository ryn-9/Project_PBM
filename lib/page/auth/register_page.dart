import 'package:flutter/material.dart';
import '../../service/authService.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final noHpController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> register() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nama, email, dan password wajib diisi"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.register(
        nama: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        noHp: noHpController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Register berhasil, silakan login")),
      );

      Navigator.pop(context);
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
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    noHpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE7378D)),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE7378D), Color(0xFFFFA6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE7378D), Color(0xFFFFA6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7378D),
                    ),
                  ),

                  const SizedBox(height: 40),

                  TextField(
                    controller: usernameController,
                    decoration: inputDecoration("Username"),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration("Email"),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: noHpController,
                    keyboardType: TextInputType.phone,
                    decoration: inputDecoration("No HP"),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: inputDecoration("Password"),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7378D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : register,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE7378D),
                      overlayColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Sudah punya akun? Login",
                      style: TextStyle(
                        color: Color(0xFFE7378D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}