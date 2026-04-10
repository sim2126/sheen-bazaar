import 'package:flutter/material.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../utils/transitions.dart';
import 'shop_detail.dart';

class ShopsList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ShopsList({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ShopsList> createState() =>
      _ShopsListState();
}

class _ShopsListState extends State<ShopsList> {
  late Future<List<ShopModel>> _shops;

  @override
  void initState() {
    super.initState();
    _shops = ShopService().getShopsByCategory(
      widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ShopModel>>(
        future: _shops,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC8821A),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong.',
              ),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/pinjra_window.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No artisans have opened their windows\nfor this category yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _ShopCard(
                shop: snapshot.data![index],
              );
            },
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopModel shop;
  const _ShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          fadeSlideRoute(ShopDetail(shop: shop)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
              child: shop.coverImage.isNotEmpty
                  ? Image.network(
                      shop.coverImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _fallbackBanner(),
                    )
                  : _fallbackBanner(),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Shop name + badges
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.shopName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3D2B1F),
                                  letterSpacing: 0.3,
                                ),
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
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                        decoration: BoxDecoration(
                          color: shop.isOpen
                              ? const Color(
                                  0xFFE8F5E9,
                                )
                              : const Color(
                                  0xFFFFEBEE,
                                ),
                          borderRadius:
                              BorderRadius.circular(
                                20,
                              ),
                        ),
                        child: Text(
                          shop.isOpen
                              ? 'Open'
                              : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            color: shop.isOpen
                                ? Colors
                                      .green[700]
                                : Colors.red[700],
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location
                  if (shop.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Color(
                            0xFF8FA8A0,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          shop.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(
                              0xFF8FA8A0,
                            ),
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Description
                  Text(
                    shop.description,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Rating + Enter button
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Color(
                              0xFFC8821A,
                            ),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Text(
                            '${shop.rating.toStringAsFixed(1)} '
                            '(${shop.totalReviews} reviews)',
                            style:
                                const TextStyle(
                                  fontSize: 12,
                                  color: Color(
                                    0xFF3D2B1F,
                                  ),
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3D2B1F,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                20,
                              ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Enter Shop',
                              style: TextStyle(
                                color: Color(
                                  0xFFF5EDE0,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons
                                  .arrow_forward_ios,
                              size: 11,
                              color: Color(
                                0xFFF5EDE0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFEDE0CC),
      child: Center(
        child: Image.asset(
          'assets/images/pinjra_window.png',
          height: 80,
          color: Colors.white24,
        ),
      ),
    );
  }
}
