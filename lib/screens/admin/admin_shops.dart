import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminShops extends StatelessWidget {
  const AdminShops({super.key});

  Stream<QuerySnapshot> get _shopsStream =>
      FirebaseFirestore.instance
          .collection('shops')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> _toggleBan(String shopId, bool currentIsOpen) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .update({'isOpen': !currentIsOpen});
  }

  Future<void> _toggleVerified(String shopId, bool currentIsVerified) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .update({'isVerified': !currentIsVerified});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('Shops & Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _shopsStream,
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
                'No shops found.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc =
                  snapshot.data!.docs[index];
              final data =
                  doc.data()
                      as Map<String, dynamic>;
              final isOpen = data['isOpen'] ?? false;
              final isVerified = data['isVerified'] ?? false;

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
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Shop header
                    ListTile(
                      contentPadding:
                          const EdgeInsets.fromLTRB(
                            14,
                            10,
                            14,
                            4,
                          ),
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(
                              0xFFEDE0CC,
                            ),
                        backgroundImage:
                            data['logo'] !=
                                    null &&
                                data['logo']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(
                                data['logo'],
                              )
                            : null,
                        child:
                            data['logo'] ==
                                    null ||
                                data['logo']
                                    .toString()
                                    .isEmpty
                            ? const Icon(LucideIcons.store, color: Color(0xFF3D2B1F), size: 22)
                            : null,
                      ),
                      title: Text(
                        data['shopName'] ?? '',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color: Color(
                            0xFF3D2B1F,
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            data['location'] ??
                                '',
                            style:
                                const TextStyle(
                                  fontSize: 12,
                                  color: Color(
                                    0xFF8FA8A0,
                                  ),
                                  fontStyle:
                                      FontStyle
                                          .italic,
                                ),
                          ),
                          Text(
                            'Category: ${data['categoryId'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors
                                  .grey[500],
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Ban/unban toggle
                          GestureDetector(
                            onTap: () => _confirmToggle(
                              context, doc.id, data['shopName'] ?? '', isOpen),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOpen ? 'Active' : 'Banned',
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isOpen ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Verify toggle
                          GestureDetector(
                            onTap: () => _toggleVerified(doc.id, isVerified),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFFFFF8E7) : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isVerified ? const Color(0xFFC9A55A) : Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified ? Icons.verified : Icons.verified_outlined,
                                    size: 12,
                                    color: isVerified ? const Color(0xFFC9A55A) : Colors.grey,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isVerified ? 'Verified' : 'Verify',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600,
                                      color: isVerified ? const Color(0xFFC8821A) : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Products subcollection
                    _ShopProductsList(
                      shopId: doc.id,
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

  void _confirmToggle(
    BuildContext context,
    String shopId,
    String shopName,
    bool isOpen,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isOpen ? 'Ban Shop' : 'Unban Shop',
        ),
        content: Text(
          isOpen
              ? 'Ban "$shopName"? It will be hidden from customers.'
              : 'Unban "$shopName"? It will be visible to customers again.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBan(shopId, isOpen);
            },
            child: Text(
              isOpen ? 'Ban' : 'Unban',
              style: TextStyle(
                color: isOpen
                    ? Colors.red[600]
                    : Colors.green[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductsList extends StatelessWidget {
  final String shopId;
  const _ShopProductsList({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              0,
              14,
              12,
            ),
            child: Text(
              'No products listed.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            12,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(
                '${products.length} product${products.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              ...products.map((p) {
                final pd =
                    p.data()
                        as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                              6,
                            ),
                        child:
                            pd['image'] != null &&
                                pd['image']
                                    .toString()
                                    .isNotEmpty
                            ? Image.network(
                                pd['image'],
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                      _,
                                      __,
                                      ___,
                                    ) =>
                                        _fallback(),
                              )
                            : _fallback(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pd['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(
                              0xFF3D2B1F,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow
                              .ellipsis,
                        ),
                      ),
                      Text(
                        '₹${pd['price']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                          color: Color(
                            0xFFB5603A,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      width: 38,
      height: 38,
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset(
          'assets/images/wicker_basket.png',
          height: 24,
          color: const Color(0x553D2B1F),
        ),
      ),
    );
  }
}
