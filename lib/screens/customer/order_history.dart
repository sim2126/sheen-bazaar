import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'write_review.dart';

class OrderHistory extends StatelessWidget {
  const OrderHistory({super.key});

  Stream<QuerySnapshot> get _ordersStream =>
      FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 50)),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet.\nStart shopping to see your orders here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.stone,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _OrderCard(orderId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderCard({required this.orderId, required this.data});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue[300]!;
      case 'dispatched': return Colors.purple[300]!;
      case 'delivered': return Colors.green[400]!;
      default: return AppColors.terracottaLight;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_outline;
      case 'dispatched': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.done_all;
      default: return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final status = data['status'] ?? 'placed';
    final total = data['total'] ?? 0;
    final shopName = data['shopName'] ?? 'Shop';
    final shopId = data['shopId'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final isDelivered = status == 'delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.walnutDeep,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.cream),
                    ),
                    const SizedBox(height: 2),
                    Text(shopName,
                      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // ── Items ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if ((item['image'] ?? '').toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item['image'],
                          width: 44, height: 44, fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) => _imgFallback(),
                        ),
                      )
                    else _imgFallback(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.cream),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('x${item['qty']}', style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Text(
                      '₹${item['price']}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.saffron),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          Divider(height: 20, indent: 14, endIndent: 14,
            color: AppColors.border),

          // ── Total + status ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${total.toString()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.cream),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 13, color: _statusColor(status)),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600, color: _statusColor(status)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Timeline ─────────────────────────────────────────────────────
          _OrderTimeline(status: status),

          // ── Review prompt (delivered only) ────────────────────────────────
          if (isDelivered && shopId.isNotEmpty)
            _ReviewPrompt(orderId: orderId, shopId: shopId, shopName: shopName),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
    width: 44, height: 44, color: AppColors.surface,
    child: const Center(
      child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 16)),
    ),
  );
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _OrderTimeline extends StatelessWidget {
  final String status;
  const _OrderTimeline({required this.status});

  int get _statusIndex {
    switch (status) {
      case 'confirmed': return 1;
      case 'dispatched': return 2;
      case 'delivered': return 3;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['Placed', 'Confirmed', 'Dispatched', 'Delivered'];
    final current = _statusIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = (i + 1) ~/ 2;
            final isCompleted = stepIndex <= current;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.terracotta : AppColors.surface,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex <= current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.terracotta : AppColors.surface,
                  border: Border.all(
                    color: isCompleted ? AppColors.terracotta : AppColors.border),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: AppColors.cream)
                    : null,
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIndex],
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: isCompleted ? AppColors.stoneLight : AppColors.stone,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Review prompt ─────────────────────────────────────────────────────────────

class _ReviewPrompt extends StatefulWidget {
  final String orderId;
  final String shopId;
  final String shopName;

  const _ReviewPrompt({
    required this.orderId,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<_ReviewPrompt> createState() => _ReviewPromptState();
}

class _ReviewPromptState extends State<_ReviewPrompt> {
  bool _reviewed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkReviewed();
  }

  Future<void> _checkReviewed() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('orderId', isEqualTo: widget.orderId)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    setState(() { _reviewed = snap.docs.isNotEmpty; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_reviewed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Row(
          children: [
            const Icon(Icons.star, size: 14, color: AppColors.saffron),
            const SizedBox(width: 6),
            Text(
              'You reviewed this order',
              style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteReview(
                orderId: widget.orderId,
                shopId: widget.shopId,
                shopName: widget.shopName,
              ),
            ),
          );
          _checkReviewed();
        },
        icon: const Icon(Icons.star_outline, size: 16),
        label: Text('Rate ${widget.shopName}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terracottaLight,
          side: const BorderSide(color: AppColors.terracotta),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
