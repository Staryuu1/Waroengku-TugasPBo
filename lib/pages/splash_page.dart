import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../models/user.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  final auth = AuthService();

  late AnimationController _circleController;
  late AnimationController _logoController;
  late AnimationController _backgroundController;

  late Animation<double> _purplePosition;
  late Animation<double> _greenPosition;
  late Animation<double> _circleSize;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late Animation<double> _backgroundProgress;

  bool _showTextLogo = false;

  static const double logoSize = 250;

  @override
  void initState() {
    super.initState();

    /// HAPUS native splash dengan aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    /// ⏳ DIPERLAMBAT
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _purplePosition = Tween(begin: -0.65, end: -0.05).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _greenPosition = Tween(begin: 0.65, end: 0.05).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _circleSize = Tween(begin: 130.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    _logoScale = Tween(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutExpo),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _backgroundProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    /// 1️⃣ Circle masuk pelan
    await _circleController.forward();

    /// 2️⃣ Logo pertama muncul
    await _logoController.forward();

    /// 3️⃣ Diam sebentar (branding moment)
    await Future.delayed(const Duration(milliseconds: 1000));

    /// 4️⃣ Background mulai berubah pelan
    _backgroundController.forward();

    /// 5️⃣ Tunggu lagi sebelum ganti logo
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() => _showTextLogo = true);
    }

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    /// Splash total ≈ 6–7 detik (sengaja biar elegan)
    await Future.delayed(const Duration(milliseconds: 3000));

    final prefs = await SharedPreferences.getInstance();
    final isSetup = prefs.getBool('isSetupComplete') ?? false;

    if (!mounted) return;

    if (!isSetup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupPage()),
      );
      return;
    }

    final User? user = await auth.getLoggedInUser();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? MainPage(user: user) : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    _logoController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _circleController,
            _logoController,
            _backgroundController,
          ]),
          builder: (_, __) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      Colors.black,
                      const Color(0xFF7B68EE),
                      _backgroundProgress.value,
                    )!,
                    Color.lerp(
                      Colors.black,
                      const Color(0xFF3DDC84),
                      _backgroundProgress.value,
                    )!,
                  ],
                ),
              ),
              child: Stack(children: [_buildCircles(size), _buildLogo()]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircles(Size size) {
    final circle = _circleSize.value;
    if (circle <= 0) return const SizedBox();

    return Stack(
      children: [
        Positioned(
          left: size.width / 2 - circle / 2,
          top: size.height * (0.5 + _purplePosition.value) - circle / 2,
          child: _circle(circle, const Color(0xFF7B68EE)),
        ),
        Positioned(
          left: size.width / 2 - circle / 2,
          top: size.height * (0.5 + _greenPosition.value) - circle / 2,
          child: _circle(circle, const Color(0xFF3DDC84)),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 50,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Opacity(
        opacity: _logoOpacity.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: SizedBox(
            width: logoSize,
            height: logoSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: !_showTextLogo
                  ? SvgPicture.asset(
                      'assets/images/Logo_1.svg',
                      key: const ValueKey('logo1'),
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      'assets/images/Logo_2.png',
                      key: const ValueKey('logo2'),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
