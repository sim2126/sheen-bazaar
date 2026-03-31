import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_required_dialog.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;

  Future<void> _placeOrder(
    CartProvider cart,
  ) async {
    if (cart.items.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) showLoginRequiredDialog(context);
      return;
    }

    setState(() => _placing = true);

    // Group items by shop
    final Map<String, List<CartItem>> byShop = {};
    for (final item in cart.items) {
      byShop
          .putIfAbsent(item.shop.id, () => [])
          .add(item);
    }

    try {
      final batch = FirebaseFirestore.instance
          .batch();

      for (final entry in byShop.entries) {
        final shopId = entry.key;
        final shopItems = entry.value;
        final total = shopItems.fold<double>(
          0,
          (acc, i) => acc + (i.product.price * i.qty),
        );

        final orderRef = FirebaseFirestore
            .instance
            .collection('orders')
            .doc();

        batch.set(orderRef, {
          'userId': uid,
          'shopId': shopId,
          'status': 'placed',
          'total': total,
          'createdAt': Timestamp.now(),
          'items': shopItems
              .map(
                (i) => {
                  'productId': i.product.id,
                  'name': i.product.name,
                  'price': i.product.price,
                  'qty': i.qty,
                  'image': i.product.image,
                },
              )
              .toList(),
        });
      }

      await batch.commit();
      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Order placed! Artisans will be notified.',
            ),
            backgroundColor: Color(0xFF3D2B1F),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _placing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text(
                      'Clear Cart',
                    ),
                    content: const Text(
                      'Remove all items from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(
                              context,
                            ),
                        child: const Text(
                          'Cancel',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color:
                                Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFFD4B896),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _emptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder:
                        (context, index) {
                          final item =
                              cart.items[index];
                          return _CartItemCard(
                            item: item,
                          );
                        },
                  ),
                ),
                _orderSummary(cart),
              ],
            ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/wicker_basket.png',
            height: 110,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Like a crisp autumn breeze...\nyour cart is currently empty.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Browse Shops'),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF3D2B1F,
            ).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cart.totalCount} item${cart.totalCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${cart.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2B1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing
                  ? null
                  : () => _placeOrder(cart),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
              ),
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                    )
                  : const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Card ──
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF3D2B1F,
            ).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(
              10,
            ),
            child: item.product.image.isNotEmpty
                ? Image.network(
                    item.product.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imgFallback(),
                  )
                : _imgFallback(),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF3D2B1F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.shop.shopName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8FA8A0),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${item.product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB5603A),
                  ),
                ),
              ],
            ),
          ),

          // Qty controls
          Column(
            children: [
              // Remove button
              GestureDetector(
                onTap: () => cart.removeItem(
                  item.product.id,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE0),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove,
                      onTap: () =>
                          cart.decrementQty(
                            item.product.id,
                          ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 14,
                          color: Color(
                            0xFF3D2B1F,
                          ),
                        ),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add,
                      onTap: () =>
                          cart.incrementQty(
                            item.product.id,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF3D2B1F),
        ),
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset(
          'assets/images/wicker_basket.png',
          height: 36,
          width: 36,
          color: const Color(0x333D2B1F),
        ),
      ),
    );
  }
}
