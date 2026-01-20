import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'register_page.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final auth = AuthService();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/Logo_main.png',
                  width: 200,
                  height: 200,
                ),

                const SizedBox(height: 40),

                // Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Username Field
                TextField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF7B68EE),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Password Field
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF7B68EE),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            User? user = await auth.login(
                              usernameCtrl.text.trim(),
                              passwordCtrl.text,
                            );
                            setState(() => _loading = false);

                            if (user != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MainPage(user: user),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Login failed")),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B68EE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: const Color(
                        0xFF7B68EE,
                      ).withOpacity(0.6),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Tidak punya akun? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );

                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created — please login'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Color(0xFF7B68EE),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
