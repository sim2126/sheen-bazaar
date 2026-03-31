import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_required_dialog.dart';
import 'cart_screen.dart';
import 'cart_icon_button.dart';

class ProductDetail extends StatelessWidget {
  final ProductModel product;
  final ShopModel shop;

  const ProductDetail({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: Text(product.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [CartIconButton()],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Product image
            SizedBox(
              height: 280,
              width: double.infinity,
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _imgFallback(),
                    )
                  : _imgFallback(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w700,
                            color: Color(
                              0xFF3D2B1F,
                            ),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w700,
                          color: Color(
                            0xFFB5603A,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Shop name
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 14,
                        color: Color(0xFF8FA8A0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.shopName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(
                            0xFF8FA8A0,
                          ),
                          fontStyle:
                              FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Craft narrative
                  Container(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                      border: const Border(
                        left: BorderSide(
                          color: Color(
                            0xFFC9A55A,
                          ),
                          width: 3,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3D2B1F,
                          ).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          '✦ About this craft',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.8,
                            color: Color(
                              0xFFC8821A,
                            ),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color:
                                Colors.grey[700],
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Details
                  Container(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3D2B1F,
                          ).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          'Category',
                          product.categoryId,
                        ),
                        _detailRow(
                          'Stock',
                          product.stock > 0
                              ? '${product.stock} available'
                              : 'Out of stock',
                        ),
                        _detailRow(
                          'Location',
                          shop.location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Add to cart / Go to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.stock > 0
                          ? () {
                              final isGuest =
                                  FirebaseAuth.instance.currentUser == null;
                              if (isGuest) {
                                showLoginRequiredDialog(context);
                                return;
                              }
                              if (inCart) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CartScreen(),
                                  ),
                                );
                              } else {
                                context
                                    .read<CartProvider>()
                                    .addItem(product, shop);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart ✓'),
                                    backgroundColor: Color(0xFF3D2B1F),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                        backgroundColor: inCart
                            ? const Color(
                                0xFFC8821A,
                              )
                            : const Color(
                                0xFF3D2B1F,
                              ),
                        disabledBackgroundColor:
                            Colors.grey[300],
                      ),
                      child: Text(
                        product.stock == 0
                            ? 'Out of Stock'
                            : inCart
                            ? 'Go to Cart →'
                            : 'Add to Cart',
                        style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2B1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset(
          'assets/images/wicker_basket.png',
          height: 64,
          color: const Color(0x333D2B1F),
        ),
      ),
    );
  }
}
