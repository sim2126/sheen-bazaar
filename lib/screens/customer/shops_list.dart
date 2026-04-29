import 'package:flutter/material.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../utils/transitions.dart';
import '../../theme/app_theme.dart';
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Something went wrong. Please try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✦', style: TextStyle(color: AppColors.stone, fontSize: 38)),
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                _ShopCard(shop: snapshot.data![index], index: index),
          );
        },
      ),
    );
  }
}

// ── Animated shop card (editorial style) ─────────────────────────────────────

class _ShopCard extends StatefulWidget {
  final ShopModel shop;
  final int index;
  const _ShopCard({required this.shop, required this.index});

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _txtFadeAnim;
  late Animation<Offset> _txtSlideAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));
    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
      ),
    );
    _txtFadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
    );
    _txtSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
    ));

    final staggerDelay =
        Duration(milliseconds: (widget.index * 140).clamp(0, 480));
    Future.delayed(staggerDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = MediaQuery.sizeOf(context).width * 0.64;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, fadeSlideRoute(ShopDetail(shop: widget.shop))),
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Square image with gold border + open/closed badge ────────
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: imgSize,
                          height: imgSize,
                          child: widget.shop.coverImage.isNotEmpty
                              ? Image.network(
                                  widget.shop.coverImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _placeholder(imgSize),
                                )
                              : _placeholder(imgSize),
                        ),
                        // Open/closed badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.walnutDeep
                                  .withValues(alpha: 0.88),
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
                                    fontSize: 13,
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

                const SizedBox(height: 30),

                // ── Text section slides up after image ───────────────────────
                SlideTransition(
                  position: _txtSlideAnim,
                  child: FadeTransition(
                    opacity: _txtFadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop name + verified badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.shop.shopName,
                                style: AppTextStyles.displayMedium,
                              ),
                            ),
                            if (widget.shop.isVerified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.saffron
                                          .withValues(alpha: 0.6)),
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
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Location
                        if (widget.shop.location.isNotEmpty) ...[
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
                        ],

                        // Description
                        Text(
                          widget.shop.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.stone,
                            height: 1.75,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Rating row
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 13, color: AppColors.saffron),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.shop.rating.toStringAsFixed(1)}  (${widget.shop.totalReviews})',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.stoneLight),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // CTA
                        Row(
                          children: [
                            Text(
                              'Enter Shop',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.terracottaLight,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward,
                                size: 13, color: AppColors.terracottaLight),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ── Thin gold separator ──────────────────────────────────────
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(double size) => Container(
        color: AppColors.surface,
        child: const Center(
          child: Text('✦',
              style: TextStyle(color: AppColors.stone, fontSize: 34)),
        ),
      );
}
