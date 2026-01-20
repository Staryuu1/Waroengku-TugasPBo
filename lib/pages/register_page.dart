import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    bool success = await auth.register(
      usernameCtrl.text.trim(),
      passwordCtrl.text,
    );
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Register success')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username already used')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
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
                      'Register',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Username Field
                  TextFormField(
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
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter username'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Password Field
                  TextFormField(
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
                      errorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter password' : null,
                  ),

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
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
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sudah punya akun? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
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
      ),
    );
  }
}
