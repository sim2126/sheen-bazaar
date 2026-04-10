import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/product_model.dart' show ProductModel, ProductDetails;
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
            // Product image — tap to zoom
            GestureDetector(
              onTap: product.image.isNotEmpty
                  ? () => _openZoom(context, product.image)
                  : null,
              child: Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: product.image.isNotEmpty
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgFallback(),
                          )
                        : _imgFallback(),
                  ),
                  if (product.image.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
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

                  // Craft description — structured if AI-generated, plain text fallback
                  if (product.details != null && !product.details!.isEmpty)
                    _StructuredDescription(
                      details: product.details!,
                      shop: shop,
                      product: product,
                    )
                  else
                    _PlainDescription(
                      description: product.description,
                      shop: shop,
                      product: product,
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

  void _openZoom(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
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

// ── Structured description (AI-generated with image) ──────────────────────────

class _StructuredDescription extends StatelessWidget {
  final ProductDetails details;
  final ShopModel shop;
  final ProductModel product;

  const _StructuredDescription({
    required this.details,
    required this.shop,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tagline
        if (details.tagline != null) ...[
          Text(
            details.tagline!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2B1F),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Narrative
        if (details.narrative != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFFC9A55A), width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3D2B1F).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✦ About this craft',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: Color(0xFFC8821A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.narrative!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Product specs grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D2B1F).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              if (details.material != null)
                _specRow('Material', details.material!),
              if (details.craft != null)
                _specRow('Craft', details.craft!),
              if (details.color != null)
                _specRow('Color', details.color!),
              if (details.dimensions != null)
                _specRow('Dimensions', details.dimensions!),
              if (details.occasion != null)
                _specRow('Occasion', details.occasion!),
              _specRow(
                'Stock',
                product.stock > 0 ? '${product.stock} available' : 'Out of stock',
              ),
              _specRow('Location', shop.location),
              if (details.care != null)
                _specRow('Care', details.care!),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D2B1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plain text fallback (products without AI-generated details) ───────────────

class _PlainDescription extends StatelessWidget {
  final String description;
  final ShopModel shop;
  final ProductModel product;

  const _PlainDescription({
    required this.description,
    required this.shop,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: Color(0xFFC9A55A), width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D2B1F).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✦ About this craft',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: Color(0xFFC8821A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D2B1F).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _detailRow('Category', product.categoryId),
              _detailRow(
                'Stock',
                product.stock > 0 ? '${product.stock} available' : 'Out of stock',
              ),
              _detailRow('Location', shop.location),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
}
