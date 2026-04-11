import 'package:flutter/material.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../utils/transitions.dart';
import '../../theme/app_theme.dart';
import 'shop_detail.dart';

// Easing curve matching website [0.22, 1, 0.36, 1]
const _kCurve = Cubic(0.22, 1, 0.36, 1);

class ShopsList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ShopsList({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ShopsList> createState() => _ShopsListState();
}

class _ShopsListState extends State<ShopsList> {
  late Future<List<ShopModel>> _shops;

  @override
  void initState() {
    super.initState();
    _shops = ShopService().getShopsByCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        title: Text(widget.categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ShopModel>>(
        future: _shops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong.', style: AppTextStyles.bodyMedium),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 36)),
                  const SizedBox(height: 16),
                  Text(
                    'No artisans have opened their\nwindows for this category yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.stone,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                _ShopCard(shop: snapshot.data![index]),
          );
        },
      ),
    );
  }
}

// ── Animated shop card ────────────────────────────────────────────────────────

class _ShopCard extends StatefulWidget {
  final ShopModel shop;
  const _ShopCard({required this.shop});

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> with TickerProviderStateMixin {
  late AnimationController _imgCtrl;
  late AnimationController _infoCtrl;
  late Animation<double> _imgAnim;
  late Animation<double> _infoAnim;

  @override
  void initState() {
    super.initState();

    _imgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _infoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _imgAnim  = CurvedAnimation(parent: _imgCtrl,  curve: _kCurve);
    _infoAnim = CurvedAnimation(parent: _infoCtrl, curve: _kCurve);

    // Info section reveals 700ms after image
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _infoCtrl.forward();
    });
  }

  @override
  void dispose() {
    _imgCtrl.dispose();
    _infoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, fadeSlideRoute(ShopDetail(shop: widget.shop))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.walnutDeep,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image (fades + zooms in) ────────────────────────────
            FadeTransition(
              opacity: _imgAnim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(_imgAnim),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: widget.shop.coverImage.isNotEmpty
                          ? Image.network(
                              widget.shop.coverImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, err, stack) =>
                                  _fallbackBanner(),
                            )
                          : _fallbackBanner(),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.walnutDeep.withValues(alpha: 0.55),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Open/closed badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.walnutDeep.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.shop.isOpen
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.shop.isOpen
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.shop.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.shop.isOpen
                                    ? Colors.green[400]
                                    : Colors.red[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Shop info (fades in after 700ms) ──────────────────────────
            FadeTransition(
              opacity: _infoAnim,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.shop.shopName,
                            style: AppTextStyles.displaySmall,
                          ),
                        ),
                        if (widget.shop.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.saffron.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 12, color: AppColors.saffron),
                                const SizedBox(width: 3),
                                Text('Verified',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.saffron)),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Location
                    if (widget.shop.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.stone),
                          const SizedBox(width: 3),
                          Text(
                            widget.shop.location,
                            style: AppTextStyles.caption
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.shop.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.stone,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Rating + Enter button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.saffron),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.shop.rating.toStringAsFixed(1)}  (${widget.shop.totalReviews})',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.stoneLight),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Enter Shop',
                                  style: AppTextStyles.button
                                      .copyWith(fontSize: 12)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 11, color: AppColors.cream),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() => Container(
        height: 200,
        width: double.infinity,
        color: AppColors.surface,
        child: const Center(
          child: Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 32)),
        ),
      );
}
