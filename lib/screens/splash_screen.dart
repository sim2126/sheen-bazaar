import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_page.dart';
import 'customer/customer_home.dart';
import 'shop_owner/shop_dashboard.dart';
import 'admin/admin_panel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              0.3,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );

    _slideAnim = Tween<double>(begin: 30, end: 0)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              0.3,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );

    _controller.forward();
    _initAndNavigate(
      withDelay: true,
    ); // 3 sec only on app launch
  }

  Future<void> _initAndNavigate({
    bool withDelay = true,
  }) async {
    if (withDelay) {
      await Future.wait([
        Future.delayed(
          const Duration(seconds: 3),
        ),
        _getDestination(),
      ]).then((results) {
        final widget = results[1] as Widget;
        if (mounted) _navigateTo(widget);
      });
    } else {
      final widget = await _getDestination();
      if (mounted) _navigateTo(widget);
    }
  }

  void _navigateTo(Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder:
            (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
        transitionDuration: const Duration(
          milliseconds: 600,
        ),
      ),
    );
  }

  Future<Widget> _getDestination() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return const CustomerHome();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return const LoginPage();

      final role = doc.data()?['role'];

      if (role == 'admin')
        return const AdminPanel(); // add this
      if (role == 'shop_owner')
        return const ShopDashboard();
      return const CustomerHome();
    } catch (_) {
      return const LoginPage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
          ),

          // ── Dark gradient overlay ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0xCC1E1208),
                ],
              ),
            ),
          ),

          // ── Brand content ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _slideAnim.value,
                  ),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/chinar_leaf.png',
                  height: 64,
                  width: 64,
                ),
                SizedBox(height: 20),
                Text(
                  'Sheen Bazaar',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFFF5EDE0),
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: 50,
                  child: Divider(
                    color: Color(0xFFC9A55A),
                    thickness: 1,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Kashmiri Crafts · Artisan Stories',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD4B896),
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // ── Falling leaves Lottie at bottom ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/Falling leaves.json',
                height: 260,
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
