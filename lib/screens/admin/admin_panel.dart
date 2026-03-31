import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/login_page.dart';
import 'admin_shops.dart';
import 'admin_orders.dart';
import 'admin_users.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  Future<void> _logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFFF5EDE0),
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ── Welcome ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2B1F),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin',
                    style: TextStyle(
                      color: Color(0xFFF5EDE0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage the Sheen Bazaar marketplace',
                    style: TextStyle(
                      color: Color(0xFF8FA8A0),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Live stats ──
            const _SectionLabel(
              label: 'Overview',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  label: 'Shops',
                  icon: const Icon(LucideIcons.store, size: 24, color: Color(0xFF3D2B1F)),
                  stream: FirebaseFirestore
                      .instance
                      .collection('shops')
                      .snapshots(),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Orders',
                  icon: const Icon(LucideIcons.receipt, size: 24, color: Color(0xFF3D2B1F)),
                  stream: FirebaseFirestore
                      .instance
                      .collection('orders')
                      .snapshots(),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Users',
                  icon: const Icon(LucideIcons.users, size: 24, color: Color(0xFF3D2B1F)),
                  stream: FirebaseFirestore
                      .instance
                      .collection('users')
                      .snapshots(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ──
            const _SectionLabel(label: 'Manage'),
            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.storefront_outlined,
              title: 'Shops & Products',
              subtitle:
                  'View all shops, browse products, ban vendors',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminShops(),
                ),
              ),
            ),

            _ActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'All Orders',
              subtitle:
                  'View every order placed on the platform',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminOrders(),
                ),
              ),
            ),

            _ActionTile(
              icon: Icons.people_outline,
              title: 'All Users',
              subtitle:
                  'View customers, vendors and their roles',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminUsers(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3D2B1F),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Widget icon;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withValues(alpha:0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                final count = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;
                return Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D2B1F),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withValues(alpha:0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE0),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3D2B1F),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D2B1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
