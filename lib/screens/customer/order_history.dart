import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8821A)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/wicker_basket.png', height: 90),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet.\nStart shopping to see your orders here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
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
      case 'confirmed': return Colors.blue;
      case 'dispatched': return Colors.purple;
      case 'delivered': return Colors.green;
      default: return Colors.orange;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D2B1F).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF3D2B1F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFFF5EDE0),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shopName,
                      style: const TextStyle(
                        color: Color(0xFF8FA8A0),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: const TextStyle(color: Color(0xFF8FA8A0), fontSize: 12),
                ),
              ],
            ),
          ),

          // Items
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
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        ),
                      )
                    else _imgFallback(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF3D2B1F)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item['qty']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${item['price']}',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB5603A),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          const Divider(height: 20, indent: 14, endIndent: 14),

          // Total + status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${total.toString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF3D2B1F),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
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
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tracking timeline
          _OrderTimeline(status: status),

          // Review button for delivered orders
          if (isDelivered && shopId.isNotEmpty)
            _ReviewPrompt(orderId: orderId, shopId: shopId, shopName: shopName),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      width: 44, height: 44,
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset('assets/images/wicker_basket.png', height: 24, color: const Color(0x553D2B1F)),
      ),
    );
  }
}

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
                color: isCompleted ? const Color(0xFFC9A55A) : const Color(0xFFE0D0BC),
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
                  color: isCompleted ? const Color(0xFFC9A55A) : const Color(0xFFE0D0BC),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  color: isCompleted ? const Color(0xFF3D2B1F) : Colors.grey,
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
            const Icon(Icons.star, size: 14, color: Color(0xFFC9A55A)),
            const SizedBox(width: 6),
            Text(
              'You reviewed this order',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
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
          foregroundColor: const Color(0xFFC8821A),
          side: const BorderSide(color: Color(0xFFC8821A)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
