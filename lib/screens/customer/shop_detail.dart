import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../services/shop_service.dart';
import '../../utils/transitions.dart';
import 'product_detail.dart';
import 'cart_icon_button.dart';

class ShopDetail extends StatefulWidget {
  final ShopModel shop;

  const ShopDetail({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetail> createState() =>
      _ShopDetailState();
}

class _ShopDetailState extends State<ShopDetail> {
  late Future<List<ProductModel>> _products;

  @override
  void initState() {
    super.initState();
    _products = ShopService().getProducts(
      widget.shop.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(
              0xFF3D2B1F,
            ),
            actions: [CartIconButton()],
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFFF5EDE0),
              ),
              onPressed: () =>
                  Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.shopName,
                style: const TextStyle(
                  color: Color(0xFFF5EDE0),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  shop.coverImage.isNotEmpty
                      ? Image.network(
                          shop.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _heroBg(),
                        )
                      : _heroBg(),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end: Alignment
                            .bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC1E1208),
                        ],
                      ),
                    ),
                  ),
                  // Glassmorphic strip at the top (AppBar area)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: kToolbarHeight,
                          color: const Color(0xFF1E1208).withValues(alpha: 0.15),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ── Artisan Strip ──
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D2B1F),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      // Logo
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            const Color(
                              0xFFC9A55A,
                            ),
                        backgroundImage:
                            shop.logo.isNotEmpty
                            ? NetworkImage(
                                shop.logo,
                              )
                            : null,
                        child: shop.logo.isEmpty
                            ? const Icon(
                                LucideIcons.user,
                                color: Color(0xFFF5EDE0),
                                size: 26,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  shop.shopName,
                                  style: const TextStyle(
                                    color: Color(0xFFF5EDE0),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (shop.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Tooltip(
                                    message: 'Verified Kashmiri Artisan',
                                    child: Icon(Icons.verified, size: 16, color: Color(0xFFC9A55A)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .location_on,
                                  size: 12,
                                  color: Color(
                                    0xFF8FA8A0,
                                  ),
                                ),
                                const SizedBox(
                                  width: 3,
                                ),
                                Text(
                                  shop.location,
                                  style: const TextStyle(
                                    color: Color(
                                      0xFF8FA8A0,
                                    ),
                                    fontSize: 12,
                                    fontStyle:
                                        FontStyle
                                            .italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .end,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(
                                  0xFFC9A55A,
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                shop.rating
                                    .toStringAsFixed(
                                      1,
                                    ),
                                style: const TextStyle(
                                  color: Color(
                                    0xFFF5EDE0,
                                  ),
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${shop.totalReviews} reviews',
                            style:
                                const TextStyle(
                                  color: Color(
                                    0xFF8FA8A0,
                                  ),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),

                // ── Open/Closed Banner ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                  color: shop.isOpen
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        shop.isOpen
                            ? Icons.storefront
                            : Icons
                                  .store_mall_directory_outlined,
                        size: 15,
                        color: shop.isOpen
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        shop.isOpen
                            ? 'This shop is currently open'
                            : 'This shop is currently closed',
                        style: TextStyle(
                          color: shop.isOpen
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Our Story ──
                Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our Story',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D2B1F),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding:
                            const EdgeInsets.all(
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
                              ).withValues(alpha:0.06),
                              blurRadius: 10,
                              offset:
                                  const Offset(
                                    0,
                                    3,
                                  ),
                            ),
                          ],
                        ),
                        child: Text(
                          shop.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color:
                                Colors.grey[700],
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Reviews Section ──
                _ReviewsSection(shopId: shop.id, isVerified: shop.isVerified),

                // ── Products Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    12,
                  ),
                  child: Text(
                    'Products',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2B1F),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Products Grid ──
          FutureBuilder<List<ProductModel>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
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

              if (!snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No products listed yet.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle:
                              FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final products = snapshot.data!;

              return SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      32,
                    ),
                sliver: SliverGrid(
                  delegate:
                      SliverChildBuilderDelegate(
                        (context, index) =>
                            _ProductCard(
                              product:
                                  products[index],
                              shop: widget.shop,
                            ),
                        childCount:
                            products.length,
                      ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
      color: const Color(0xFF3D2B1F),
      child: Center(
        child: Image.asset(
          'assets/images/pinjra_window.png',
          height: 120,
          color: Colors.white24,
        ),
      ),
    );
  }
}

// ── Product Card Widget ──
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ShopModel shop;

  const _ProductCard({
    required this.product,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          fadeSlideRoute(ProductDetail(
            product: product,
            shop: shop,
          )),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withValues(alpha:0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _imgFallback(),
                      )
                    : _imgFallback(),
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D2B1F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB5603A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock indicator
                  Text(
                    product.stock > 0
                        ? '${product.stock} in stock'
                        : 'Out of stock',
                    style: TextStyle(
                      fontSize: 11,
                      color: product.stock > 0
                          ? Colors.green[600]
                          : Colors.red[400],
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
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset(
          'assets/images/wicker_basket.png',
          height: 40,
          color: const Color(0x333D2B1F),
        ),
      ),
    );
  }
}

// ── Reviews Section ──────────────────────────────────────────────────────────

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
              Text(
                'Customer Reviews',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2B1F),
                  letterSpacing: 0.4,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC9A55A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Color(0xFFC9A55A)),
                      SizedBox(width: 4),
                      Text(
                        'Verified Artisan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFC8821A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3D2B1F).withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF3D2B1F),
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: const Color(0xFFC9A55A),
                          )),
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
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
