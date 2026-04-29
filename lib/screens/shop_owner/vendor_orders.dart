import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorOrders extends StatelessWidget {
  final String shopId;
  const VendorOrders({
    super.key,
    required this.shopId,
  });

  Stream<QuerySnapshot> get _ordersStream =>
      FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> _updateStatus(
    String orderId,
    String status,
  ) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC8821A),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/wicker_basket.png',
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data =
                  doc.data()
                      as Map<String, dynamic>;
              final items =
                  List<Map<String, dynamic>>.from(
                    data['items'] ?? [],
                  );
              final status =
                  data['status'] ?? 'placed';
              final total = data['total'] ?? 0;
              final createdAt =
                  (data['createdAt'] as Timestamp)
                      .toDate();

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
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
                child: Padding(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Order ID + date
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            'Order #${doc.id.substring(0, 8).toUpperCase()}',
                            style:
                                const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  fontSize: 15,
                                  color: Color(
                                    0xFF3D2B1F,
                                  ),
                                ),
                          ),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors
                                  .grey[500],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Items list
                      ...items.map(
                        (item) => Padding(
                          padding:
                              const EdgeInsets.only(
                                bottom: 6,
                              ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(
                                      0xFF3D2B1F,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'x${item['qty']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors
                                      .grey[500],
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                '₹${item['price']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color: Color(
                                    0xFFB5603A,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 16),

                      // Total + status row
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            'Total: ₹$total',
                            style:
                                const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  fontSize: 16,
                                  color: Color(
                                    0xFF3D2B1F,
                                  ),
                                ),
                          ),
                          _StatusDropdown(
                            orderId: doc.id,
                            currentStatus: status,
                            onChanged:
                                _updateStatus,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String orderId;
  final String currentStatus;
  final Future<void> Function(String, String)
  onChanged;

  const _StatusDropdown({
    required this.orderId,
    required this.currentStatus,
    required this.onChanged,
  });

  Color get _statusColor {
    switch (currentStatus) {
      case 'placed':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'dispatched':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withValues(alpha:0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          isDense: true,
          dropdownColor: Colors.white,
          style: TextStyle(
            color: _statusColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(
              value: 'placed',
              child: Text('Placed'),
            ),
            DropdownMenuItem(
              value: 'confirmed',
              child: Text('Confirmed'),
            ),
            DropdownMenuItem(
              value: 'dispatched',
              child: Text('Dispatched'),
            ),
            DropdownMenuItem(
              value: 'delivered',
              child: Text('Delivered'),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(orderId, v);
          },
        ),
      ),
    );
  }
}
