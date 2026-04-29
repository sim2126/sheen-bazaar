import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/product_model.dart' show ProductModel, ProductDetails;
import '../../models/shop_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/login_required_dialog.dart';
import '../../theme/app_theme.dart';
import 'cart_screen.dart';
import 'cart_icon_button.dart';

class ProductDetail extends StatelessWidget {
  final ProductModel product;
  final ShopModel shop;

  const ProductDetail({super.key, required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(product.id);

    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: Text(product.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [CartIconButton()],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image — tap to zoom ──────────────────────────────
            GestureDetector(
              onTap: product.image.isNotEmpty
                  ? () => _openZoom(context, product.image)
                  : null,
              child: Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: product.image.isNotEmpty
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, err, stack) => _imgFallback(),
                          )
                        : _imgFallback(),
                  ),
                  // Gradient fade to walnut at bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.6, 1.0],
                          colors: [Colors.transparent, AppColors.walnut],
                        ),
                      ),
                    ),
                  ),
                  if (product.image.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.walnutDeep.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.zoom_in, color: AppColors.cream, size: 18),
                      ),
                    ),
                ],
              ),
            ),

            // ── Product info card ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.displayMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Shop name
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 14, color: AppColors.stone),
                      const SizedBox(width: 4),
                      Text(
                        shop.shopName,
                        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
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

                  // ── CTA button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.stock > 0
                          ? () {
                              if (FirebaseAuth.instance.currentUser == null) {
                                showLoginRequiredDialog(context);
                                return;
                              }
                              if (inCart) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              } else {
                                context.read<CartProvider>().addItem(product, shop);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Added to cart ✓'),
                                    backgroundColor: AppColors.surface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: AppColors.cardBorder),
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: inCart ? AppColors.terracottaLight : AppColors.terracotta,
                        disabledBackgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        product.stock == 0
                            ? 'Out of Stock'
                            : inCart
                                ? 'Go to Cart →'
                                : 'Add to Cart',
                        style: AppTextStyles.button.copyWith(fontSize: 18),
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
            iconTheme: const IconThemeData(color: AppColors.cream),
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
      color: AppColors.surface,
      child: const Center(
        child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 42)),
      ),
    );
  }
}

// ── Structured description (AI-generated) ────────────────────────────────────

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
        if (details.tagline != null) ...[
          Text(
            details.tagline!,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.stoneLight,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (details.narrative != null) ...[
          _craftBox(details.narrative!),
          const SizedBox(height: 12),
        ],
        _specsGrid(context),
      ],
    );
  }

  Widget _craftBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.terracotta, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦  ABOUT THIS CRAFT',
            style: AppTextStyles.label.copyWith(color: AppColors.terracottaLight),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.stone,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specsGrid(BuildContext context) {
    final rows = <Widget>[];
    if (details.material != null) rows.add(_specRow('Material', details.material!));
    if (details.craft != null) rows.add(_specRow('Craft', details.craft!));
    if (details.color != null) rows.add(_specRow('Colour', details.color!));
    if (details.dimensions != null) rows.add(_specRow('Dimensions', details.dimensions!));
    if (details.occasion != null) rows.add(_specRow('Occasion', details.occasion!));
    rows.add(_specRow('Stock', product.stock > 0 ? '${product.stock} available' : 'Out of stock'));
    rows.add(_specRow('Location', shop.location));
    if (details.care != null) rows.add(_specRow('Care', details.care!));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card,
      child: Column(children: rows),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plain text fallback ───────────────────────────────────────────────────────

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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: AppColors.terracotta, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✦  ABOUT THIS CRAFT',
                style: AppTextStyles.label.copyWith(color: AppColors.terracottaLight),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.stone,
                  fontStyle: FontStyle.italic,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card,
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}
