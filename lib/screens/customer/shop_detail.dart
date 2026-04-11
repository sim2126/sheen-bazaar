import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../services/shop_service.dart';
import '../../utils/transitions.dart';
import '../../theme/app_theme.dart';
import 'product_detail.dart';
import 'cart_icon_button.dart';

class ShopDetail extends StatefulWidget {
  final ShopModel shop;
  const ShopDetail({super.key, required this.shop});

  @override
  State<ShopDetail> createState() => _ShopDetailState();
}

class _ShopDetailState extends State<ShopDetail> {
  late Future<List<ProductModel>> _products;

  @override
  void initState() {
    super.initState();
    _products = ShopService().getProducts(widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return Scaffold(
      backgroundColor: AppColors.walnut,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.walnutDeep,
            actions: [CartIconButton()],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.cream),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.shopName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  shop.coverImage.isNotEmpty
                      ? Image.network(
                          shop.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _heroBg(),
                        )
                      : _heroBg(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD1A130A)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: kToolbarHeight,
                          color: AppColors.walnutDeep.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Artisan strip ────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.walnutDeep,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.terracottaLight,
                          backgroundImage:
                              shop.logo.isNotEmpty ? NetworkImage(shop.logo) : null,
                          child: shop.logo.isEmpty
                              ? const Icon(LucideIcons.user, color: AppColors.cream, size: 26)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      shop.shopName,
                                      style: AppTextStyles.displaySmall,
                                    ),
                                  ),
                                  if (shop.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Tooltip(
                                      message: 'Verified Kashmiri Artisan',
                                      child: Icon(Icons.verified, size: 15, color: AppColors.saffron),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.stone),
                                  const SizedBox(width: 3),
                                  Text(shop.location, style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.saffron),
                                const SizedBox(width: 3),
                                Text(shop.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text('${shop.totalReviews} reviews', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Open/Closed banner ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: shop.isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shop.isOpen ? 'This shop is currently open' : 'This shop is currently closed',
                        style: AppTextStyles.caption.copyWith(
                          color: shop.isOpen ? Colors.green[400] : Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Our Story ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Story', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: AppColors.terracotta, width: 3),
                          ),
                        ),
                        child: Text(
                          shop.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.stone,
                            fontStyle: FontStyle.italic,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Reviews ──────────────────────────────────────────────
                _ReviewsSection(shopId: shop.id, isVerified: shop.isVerified),

                // ── Products header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text('Products', style: AppTextStyles.displayMedium),
                ),
              ],
            ),
          ),

          // ── Products grid ────────────────────────────────────────────────
          FutureBuilder<List<ProductModel>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/Falling leaves.json',
                      height: 180,
                      repeat: true,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No products listed yet.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.stone,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(
                      product: snapshot.data![index],
                      shop: widget.shop,
                    ),
                    childCount: snapshot.data!.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _heroBg() {
    return Container(
      color: AppColors.walnutDeep,
      child: const Center(
        child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 40)),
      ),
    );
  }
}

// ── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ShopModel shop;
  const _ProductCard({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(ProductDetail(product: product, shop: shop)),
      ),
      child: Container(
        decoration: AppDecorations.cardElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, err, stack) => _imgFallback(),
                      )
                    : _imgFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.cream,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.saffron,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.stock > 0 ? '${product.stock} in stock' : 'Out of stock',
                    style: AppTextStyles.caption.copyWith(
                      color: product.stock > 0 ? Colors.green[400] : Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 24)),
      ),
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final String shopId;
  final bool isVerified;
  const _ReviewsSection({required this.shopId, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Customer Reviews', style: AppTextStyles.displayMedium),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.saffron.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 11, color: AppColors.saffron),
                      const SizedBox(width: 3),
                      Text('Verified Artisan',
                          style: AppTextStyles.caption.copyWith(color: AppColors.saffron)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('shopId', isEqualTo: shopId)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No reviews yet. Be the first to share your experience!',
                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                );
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final rating = (d['rating'] ?? 0) as int;
                  final comment = d['comment'] ?? '';
                  final userName = d['userName'] ?? 'Customer';
                  final date = (d['createdAt'] as Timestamp).toDate();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: AppDecorations.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(userName,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600, color: AppColors.cream)),
                            Text('${date.day}/${date.month}/${date.year}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 13,
                              color: AppColors.saffron,
                            ),
                          ),
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(comment,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.stone, height: 1.5)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
