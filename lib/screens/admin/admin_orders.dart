import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrders extends StatelessWidget {
  const AdminOrders({super.key});

  Stream<QuerySnapshot> get _ordersStream =>
      FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Color _statusColor(String status) {
    switch (status) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('All Orders'),
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
            return const Center(
              child: Text(
                'No orders yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
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
              final createdAt =
                  (data['createdAt'] as Timestamp)
                      .toDate();

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF3D2B1F,
                      ).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Order ID + status
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text(
                          '#${doc.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 15,
                            color: Color(
                              0xFF3D2B1F,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              status,
                            ).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(
                                  20,
                                ),
                          ),
                          child: Text(
                            status[0]
                                    .toUpperCase() +
                                status.substring(
                                  1,
                                ),
                            style: TextStyle(
                              color: _statusColor(
                                status,
                              ),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Meta info
                    Text(
                      'User: ${data['userId'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Shop: ${data['shopId'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Date: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),

                    const Divider(height: 16),

                    // Items
                    ...items.map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.only(
                              bottom: 4,
                            ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']} x${item['qty']}',
                                style:
                                    const TextStyle(
                                      fontSize:
                                          12,
                                      color: Color(
                                        0xFF3D2B1F,
                                      ),
                                    ),
                              ),
                            ),
                            Text(
                              '₹${item['price']}',
                              style:
                                  const TextStyle(
                                    fontSize: 14,
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

                    const Divider(height: 12),

                    // Total
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            color: Color(
                              0xFF3D2B1F,
                            ),
                          ),
                        ),
                        Text(
                          '₹${data['total']}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 17,
                            color: Color(
                              0xFFB5603A,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
