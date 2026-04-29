import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VendorAnalytics extends StatefulWidget {
  final String shopId;
  const VendorAnalytics({super.key, required this.shopId});

  @override
  State<VendorAnalytics> createState() => _VendorAnalyticsState();
}

class _VendorAnalyticsState extends State<VendorAnalytics> {
  bool _loading = true;

  int _totalOrders = 0;
  int _thisMonthOrders = 0;
  double _totalRevenue = 0;
  double _thisMonthRevenue = 0;
  List<_ProductStat> _bestSellers = [];
  List<_LowStockItem> _lowStock = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final monthStart = Timestamp.fromDate(DateTime(now.year, now.month, 1));

    // Fetch all orders for this shop
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    int totalOrders = 0;
    int thisMonthOrders = 0;
    double totalRevenue = 0;
    double thisMonthRevenue = 0;
    final Map<String, _ProductStat> productStats = {};

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp;
      final total = (data['total'] ?? 0.0) as num;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

      totalOrders++;
      totalRevenue += total.toDouble();

      if (createdAt.compareTo(monthStart) >= 0) {
        thisMonthOrders++;
        thisMonthRevenue += total.toDouble();
      }

      for (final item in items) {
        final name = item['name'] ?? '';
        final qty = (item['qty'] ?? 1) as int;
        final price = (item['price'] ?? 0.0) as num;
        if (name.isEmpty) continue;
        productStats.putIfAbsent(name, () => _ProductStat(name: name));
        productStats[name]!.totalQty += qty;
        productStats[name]!.totalRevenue += price.toDouble() * qty;
      }
    }

    // Sort best sellers by qty
    final bestSellers = productStats.values.toList()
      ..sort((a, b) => b.totalQty.compareTo(a.totalQty));

    // Fetch low stock products (stock <= 3)
    final productsSnap = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('products')
        .get();

    final lowStock = productsSnap.docs
        .where((d) => (d['stock'] ?? 0) as int <= 3)
        .map((d) => _LowStockItem(name: d['name'] ?? '', stock: (d['stock'] ?? 0) as int))
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    setState(() {
      _totalOrders = totalOrders;
      _thisMonthOrders = thisMonthOrders;
      _totalRevenue = totalRevenue;
      _thisMonthRevenue = thisMonthRevenue;
      _bestSellers = bestSellers.take(5).toList();
      _lowStock = lowStock;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8821A)))
          : RefreshIndicator(
              color: const Color(0xFFC8821A),
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── This Month ──
                    _SectionLabel('This Month'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          icon: const Icon(LucideIcons.shoppingBag, size: 22, color: Color(0xFF3D2B1F)),
                          label: 'Orders',
                          value: '$_thisMonthOrders',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          icon: const Icon(LucideIcons.indianRupee, size: 22, color: Color(0xFF3D2B1F)),
                          label: 'Revenue',
                          value: '₹${_thisMonthRevenue.toStringAsFixed(0)}',
                        )),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── All Time ──
                    _SectionLabel('All Time'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatCard(
                          icon: const Icon(LucideIcons.clipboardList, size: 22, color: Color(0xFF3D2B1F)),
                          label: 'Total Orders',
                          value: '$_totalOrders',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          icon: Image.asset('assets/images/chinar_leaf.png', height: 22, width: 22),
                          label: 'Total Revenue',
                          value: '₹${_totalRevenue.toStringAsFixed(0)}',
                        )),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Best Sellers ──
                    _SectionLabel('Best Sellers'),
                    const SizedBox(height: 10),
                    if (_bestSellers.isEmpty)
                      _emptyCard('No sales yet. Your first order will appear here.')
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF3D2B1F).withValues(alpha: 0.06),
                            blurRadius: 8, offset: const Offset(0, 2),
                          )],
                        ),
                        child: Column(
                          children: _bestSellers.asMap().entries.map((e) {
                            final i = e.key;
                            final ps = e.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < _bestSellers.length - 1
                                    ? const Border(bottom: BorderSide(color: Color(0xFFF0E6D8)))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26, height: 26,
                                    decoration: BoxDecoration(
                                      color: i == 0 ? const Color(0xFFC9A55A) : const Color(0xFFF5EDE0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w700,
                                            color: i == 0 ? Colors.white : const Color(0xFF3D2B1F),
                                          )),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(ps.name,
                                        style: const TextStyle(fontSize: 15, color: Color(0xFF3D2B1F)),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${ps.totalQty} sold',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC8821A))),
                                      Text('₹${ps.totalRevenue.toStringAsFixed(0)}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Low Stock Alerts ──
                    Row(
                      children: [
                        _SectionLabel('Low Stock Alerts'),
                        if (_lowStock.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_lowStock.length}',
                              style: TextStyle(fontSize: 14, color: Colors.red[700], fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_lowStock.isEmpty)
                      _emptyCard('All products are well stocked.')
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade100),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF3D2B1F).withValues(alpha: 0.06),
                            blurRadius: 8, offset: const Offset(0, 2),
                          )],
                        ),
                        child: Column(
                          children: _lowStock.asMap().entries.map((e) {
                            final i = e.key;
                            final item = e.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < _lowStock.length - 1
                                    ? const Border(bottom: BorderSide(color: Color(0xFFF0E6D8)))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.stock == 0 ? Icons.warning_rounded : Icons.warning_amber_rounded,
                                    color: item.stock == 0 ? Colors.red[600] : Colors.orange[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(item.name,
                                        style: const TextStyle(fontSize: 15, color: Color(0xFF3D2B1F)),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.stock == 0 ? Colors.red[50] : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.stock == 0 ? 'Out of stock' : '${item.stock} left',
                                      style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: item.stock == 0 ? Colors.red[700] : Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 15)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Color(0xFF3D2B1F), letterSpacing: 0.3,
        ));
  }
}

class _StatCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: const Color(0xFF3D2B1F).withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF3D2B1F))),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ProductStat {
  final String name;
  int totalQty = 0;
  double totalRevenue = 0;
  _ProductStat({required this.name});
}

class _LowStockItem {
  final String name;
  final int stock;
  _LowStockItem({required this.name, required this.stock});
}
