import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/shop_model.dart';
import 'create_shop.dart';
import 'manage_products.dart';
import 'vendor_orders.dart';
import 'vendor_analytics.dart';
import '../auth/login_page.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() =>
      _ShopDashboardState();
}

class _ShopDashboardState
    extends State<ShopDashboard> {
  final uid =
      FirebaseAuth.instance.currentUser!.uid;
  ShopModel? _shop;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchShop();
  }

  Future<void> _fetchShop() async {
    final snapshot = await FirebaseFirestore
        .instance
        .collection('shops')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    setState(() {
      _shop = snapshot.docs.isNotEmpty
          ? ShopModel.fromMap(
              snapshot.docs.first.id,
              snapshot.docs.first.data(),
            )
          : null;
      _loading = false;
    });
  }

  Future<void> _toggleOpen() async {
    if (_shop == null) return;
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(_shop!.id)
        .update({'isOpen': !_shop!.isOpen});
    _fetchShop();
  }

  // In shop_dashboard.dart _logout():
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
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
        title: const Text('My Shop Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFFF5EDE0),
            ),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC8821A),
              ),
            )
          : _shop == null
          ? _noShopView()
          : _dashboardView(),
    );
  }

  // ── No shop yet ──
  Widget _noShopView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pinjra_window.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'You don\'t have a shop yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D2B1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The artisan is resting.\nCreate your shop to open your windows to the bazaar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CreateShop(),
                  ),
                );
                _fetchShop();
              },
              icon: const Icon(
                Icons.add_business,
              ),
              label: const Text('Create My Shop'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard view ──
  Widget _dashboardView() {
    final shop = _shop!;

    return RefreshIndicator(
      color: const Color(0xFFC8821A),
      onRefresh: _fetchShop,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ── Shop header card ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3D2B1F),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Cover image
                  if (shop.coverImage.isNotEmpty)
                    Image.network(
                      shop.coverImage,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              const Color(
                                0xFFC9A55A,
                              ),
                          backgroundImage:
                              shop.logo.isNotEmpty
                              ? NetworkImage(
                                  shop.logo,
                                )
                              : null,
                          child: shop.logo.isEmpty
                              ? const Icon(
                                  LucideIcons.user,
                                  color: Color(0xFFF5EDE0),
                                  size: 26,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                shop.shopName,
                                style: const TextStyle(
                                  color: Color(
                                    0xFFF5EDE0,
                                  ),
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .location_on,
                                    size: 12,
                                    color: Color(
                                      0xFF8FA8A0,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Text(
                                    shop.location,
                                    style: const TextStyle(
                                      color: Color(
                                        0xFF8FA8A0,
                                      ),
                                      fontSize:
                                          12,
                                      fontStyle:
                                          FontStyle
                                              .italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 13,
                                    color: Color(
                                      0xFFC9A55A,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Text(
                                    '${shop.rating.toStringAsFixed(1)} · ${shop.totalReviews} reviews',
                                    style: const TextStyle(
                                      color: Color(
                                        0xFF8FA8A0,
                                      ),
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Open/Close toggle
                        Column(
                          children: [
                            Switch(
                              value: shop.isOpen,
                              onChanged: (_) =>
                                  _toggleOpen(),
                              activeColor:
                                  const Color(
                                    0xFFC9A55A,
                                  ),
                            ),
                            Text(
                              shop.isOpen
                                  ? 'Open'
                                  : 'Closed',
                              style: TextStyle(
                                color: shop.isOpen
                                    ? const Color(
                                        0xFFC9A55A,
                                      )
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick stats ──
            _SectionLabel(label: 'Overview'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Image.asset('assets/images/chinar_leaf.png', height: 24, width: 24),
                    label: 'Rating',
                    value: shop.rating
                        .toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: const Icon(LucideIcons.messageSquare, size: 24, color: Color(0xFF3D2B1F)),
                    label: 'Reviews',
                    value: '${shop.totalReviews}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: const Icon(LucideIcons.packageOpen, size: 24, color: Color(0xFF3D2B1F)),
                    label: 'Status',
                    value: shop.isOpen
                        ? 'Open'
                        : 'Closed',
                    valueColor: shop.isOpen
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ──
            _SectionLabel(label: 'Manage'),
            const SizedBox(height: 10),

            _ActionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Shop Details',
              subtitle:
                  'Update name, description, location, images',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateShop(
                      existingShop: shop,
                    ),
                  ),
                );
                _fetchShop();
              },
            ),

            _ActionTile(
              icon: Icons.inventory_2_outlined,
              title: 'Manage Products',
              subtitle:
                  'Add, edit or remove your product listings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManageProducts(
                          shopId: shop.id,
                        ),
                  ),
                );
              },
            ),

            _ActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'View Orders',
              subtitle: 'See all orders placed at your shop',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VendorOrders(shopId: shop.id)),
                );
              },
            ),

            _ActionTile(
              icon: Icons.bar_chart_rounded,
              title: 'Analytics',
              subtitle: 'Sales, revenue, best sellers & low stock alerts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VendorAnalytics(shopId: shop.id)),
                );
              },
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
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3D2B1F),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  const Color(0xFF3D2B1F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D2B1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
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
