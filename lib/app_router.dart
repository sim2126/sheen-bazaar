import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/customer/customer_home.dart';
import 'screens/shop_owner/shop_dashboard.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/auth/login_page.dart';

/// Checks auth state and routes to the correct screen with zero visual gap.
/// Shows the same background as [CustomerHome]'s hero while the Firestore
/// role fetch runs, so the transition is seamless.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final user = FirebaseAuth.instance.currentUser;
    Widget dest;

    if (user == null) {
      dest = const CustomerHome();
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'];
        if (role == 'admin') {
          dest = const AdminPanel();
        } else if (role == 'shop_owner') {
          dest = const ShopDashboard();
        } else {
          dest = const CustomerHome();
        }
      } catch (_) {
        dest = const LoginPage();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => dest,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shows the same background image as CustomerHome's hero so there is
    // zero visible flash when the route replaces this screen.
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.25, 1.0],
                colors: [Colors.transparent, Color(0xF01A130A)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
