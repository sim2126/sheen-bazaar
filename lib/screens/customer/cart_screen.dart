import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_required_dialog.dart';
import '../../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) return;

    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) showLoginRequiredDialog(context);
      return;
    }

    setState(() => _placing = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('placeOrder');
      final result = await callable.call<Map>({
        'items': cart.items.map((i) => {
          'shopId': i.shop.id,
          'productId': i.product.id,
          'qty': i.qty,
        }).toList(),
      });
      final orderCount = result.data['count'] ?? 1;
      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              orderCount == 1
                  ? 'Order placed! Artisan will be notified.'
                  : '$orderCount orders placed! Artisans will be notified.',
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not place order.'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.surface),
        );
      }
    }

    if (mounted) setState(() => _placing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text('Clear Cart', style: AppTextStyles.displaySmall),
                    content: Text(
                      'Remove all items from your cart?',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.stone),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: AppTextStyles.bodySmall),
                      ),
                      TextButton(
                        onPressed: () { cart.clear(); Navigator.pop(context); },
                        child: Text('Clear',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.terracotta)),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Clear',
                style: AppTextStyles.caption.copyWith(color: AppColors.stone)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _emptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) =>
                        _CartItemCard(item: cart.items[index]),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 50)),
          const SizedBox(height: 20),
          Text('Your cart is empty', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Like a crisp autumn breeze...\nyour cart awaits.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.stone,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('Browse Shops', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.walnutDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cart.totalCount} item${cart.totalCount > 1 ? 's' : ''}',
                style: AppTextStyles.caption,
              ),
              Text(
                '₹${cart.totalPrice.toStringAsFixed(0)}',
                style: AppTextStyles.price,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing ? null : () => _placeOrder(cart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.terracotta,
                disabledBackgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _placing
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.cream, strokeWidth: 2),
                    )
                  : Text('Place Order', style: AppTextStyles.button.copyWith(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardElevated,
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product.image.isNotEmpty
                ? Image.network(
                    item.product.image,
                    width: 70, height: 70, fit: BoxFit.cover,
                    errorBuilder: (context, err, stack) => _imgFallback(),
                  )
                : _imgFallback(),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.cream),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.shop.shopName,
                  style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${item.product.price.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.saffron),
                ),
              ],
            ),
          ),

          // Qty controls
          Column(
            children: [
              GestureDetector(
                onTap: () => cart.removeItem(item.product.id),
                child: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.stone),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.walnut,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _qtyBtn(icon: Icons.remove,
                      onTap: () => cart.decrementQty(item.product.id)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.qty}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.cream),
                      ),
                    ),
                    _qtyBtn(icon: Icons.add,
                      onTap: () => cart.incrementQty(item.product.id)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.terracottaLight),
      ),
    );
  }

  Widget _imgFallback() => Container(
    width: 70, height: 70, color: AppColors.surface,
    child: const Center(
      child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 22)),
    ),
  );
}
