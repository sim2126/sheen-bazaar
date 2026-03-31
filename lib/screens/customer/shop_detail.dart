import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../services/shop_service.dart';
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
                              (_, __, ___) =>
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
                Container(
                  color: const Color(0xFF3D2B1F),
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                            Text(
                              shop.shopName,
                              style:
                                  const TextStyle(
                                    color: Color(
                                      0xFFF5EDE0,
                                    ),
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
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
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          CircularProgressIndicator(
                            color: Color(
                              0xFFC8821A,
                            ),
                          ),
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
          MaterialPageRoute(
            builder: (_) => ProductDetail(
              product: product,
              shop: shop,
            ),
          ),
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
                            (_, __, ___) =>
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
