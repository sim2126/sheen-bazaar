import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../utils/transitions.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/hamburger_menu.dart';
import '../../widgets/login_required_dialog.dart';
import 'shops_list.dart';
import 'ai_assistant.dart';
import 'order_history.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import '../auth/login_page.dart';

// Easing curve matching website [0.22, 1, 0.36, 1]
const _kCurve = Cubic(0.22, 1, 0.36, 1);

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome>
    with TickerProviderStateMixin {
  late Future<List<CategoryModel>> _categories;
  StreamSubscription<User?>? _authSub;

  // ── Intro animation controllers ────────────────────────────────────────────
  late AnimationController _lottieCtrl;       // drives Lottie playback
  late AnimationController _titleCtrl;        // left-to-right text reveal
  late AnimationController _taglineCtrl;      // left-to-right text reveal
  late AnimationController _bounceCtrl;       // chevron bounce (loops)

  late Animation<double> _titleAnim;
  late Animation<double> _taglineAnim;
  late Animation<double> _bounceAnim;

  bool _lottieVisible = true;
  bool _dividerVisible = false;
  bool _chevronVisible = false;

  @override
  void initState() {
    super.initState();
    _categories = CategoryService().getCategories();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });

    _lottieCtrl = AnimationController(vsync: this);

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleAnim = CurvedAnimation(parent: _titleCtrl, curve: _kCurve);

    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineAnim = CurvedAnimation(parent: _taglineCtrl, curve: _kCurve);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  /// Called when the Lottie animation finishes playing.
  /// Fades out the Lottie overlay, then sequences the text reveals.
  void _onLottieDone() {
    if (!mounted) return;
    setState(() => _lottieVisible = false);

    // Wait for AnimatedOpacity fade (400 ms) + small pause
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _titleCtrl.forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _dividerVisible = true);
        _taglineCtrl.forward().whenComplete(() {
          if (!mounted) return;
          setState(() => _chevronVisible = true);
        });
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _lottieCtrl.dispose();
    _titleCtrl.dispose();
    _taglineCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  void _openMenu() {
    final cartCount = context.read<CartProvider>().items.length;
    final ctx = context;
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (dialogCtx, a, b) => HamburgerMenu(
        isGuest: _isGuest,
        cartCount: cartCount,
        onClose: () => Navigator.pop(dialogCtx),
        onSearch: () {
          Navigator.pop(dialogCtx);
          Navigator.push(ctx, fadeSlideRoute(const SearchScreen()));
        },
        onCart: () {
          Navigator.pop(dialogCtx);
          Navigator.push(ctx, fadeSlideRoute(const CartScreen()));
        },
        onOrders: () {
          Navigator.pop(dialogCtx);
          if (_isGuest) {
            showLoginRequiredDialog(ctx);
          } else {
            Navigator.push(ctx, fadeSlideRoute(const OrderHistory()));
          }
        },
        onAI: () {
          Navigator.pop(dialogCtx);
          if (_isGuest) {
            showLoginRequiredDialog(ctx);
          } else {
            Navigator.push(ctx, fadeSlideRoute(const AiAssistant()));
          }
        },
        onAuthAction: () {
          Navigator.pop(dialogCtx);
          if (_isGuest) {
            Navigator.push(ctx, fadeSlideRoute(const LoginPage(returnAfterLogin: true)));
          } else {
            FirebaseAuth.instance.signOut();
          }
        },
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  // ── Left-to-right text reveal using ShaderMask ────────────────────────────
  Widget _reveal(Animation<double> anim, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, inner) {
        final v = anim.value;
        if (v <= 0.001) return Opacity(opacity: 0, child: inner);
        if (v >= 0.999) return inner!;
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, v, (v + 0.001).clamp(0.0, 1.0)],
          ).createShader(rect),
          blendMode: BlendMode.modulate,
          child: inner,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.walnut,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.cream, size: 24),
            onPressed: _openMenu,
          ),
        ],
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categories,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // ── Full-screen hero ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: screenH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image (always visible)
                      Image.asset(
                        'assets/images/splash_bg.jpg',
                        fit: BoxFit.cover,
                      ),

                      // Dark gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.25, 1.0],
                            colors: [Colors.transparent, Color(0xF01A130A)],
                          ),
                        ),
                      ),

                      // ── Full-screen Lottie (plays once, then fades out) ──
                      AnimatedOpacity(
                        opacity: _lottieVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: IgnorePointer(
                          child: Lottie.asset(
                            'assets/lottie/Falling leaves.json',
                            controller: _lottieCtrl,
                            width: screenW,
                            height: screenH,
                            fit: BoxFit.cover,
                            onLoaded: (composition) {
                              // Cap playback at 3 s so we don't wait forever
                              _lottieCtrl.duration = Duration(
                                milliseconds: min(
                                  composition.duration.inMilliseconds,
                                  3000,
                                ),
                              );
                              _lottieCtrl
                                  .forward()
                                  .whenComplete(_onLottieDone);
                            },
                          ),
                        ),
                      ),

                      // ── Brand text (sequenced reveal) ────────────────────
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // "Sheen Bazaar" — left-to-right reveal
                            _reveal(
                              _titleAnim,
                              Text(
                                'Sheen Bazaar',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.cream,
                                  letterSpacing: 1.6,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 12,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Gold divider — fades in with tagline
                            AnimatedOpacity(
                              opacity: _dividerVisible ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: Container(
                                  width: 50, height: 1, color: AppColors.gold),
                            ),

                            const SizedBox(height: 14),

                            // Tagline — left-to-right reveal
                            _reveal(
                              _taglineAnim,
                              Text(
                                'Kashmiri Crafts · Artisan Stories',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.cream,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Scroll hint (fades in after tagline) ────────────
                      Positioned(
                        bottom: 32,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: _chevronVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: AnimatedBuilder(
                            animation: _bounceCtrl,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _bounceAnim.value),
                              child: child,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore Crafts',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.stoneLight,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.stoneLight,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section label ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: Container(height: 1, color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('BROWSE COLLECTIONS',
                            style: AppTextStyles.label),
                      ),
                      Expanded(
                          child: Container(height: 1, color: AppColors.border)),
                    ],
                  ),
                ),
              ),

              // ── Category list ─────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.terracotta),
                    ),
                  ),
                )
              else if (categories.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('No categories found',
                          style: AppTextStyles.bodyMedium),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CategoryCard(
                        category: categories[index],
                        index: index,
                      ),
                      childCount: categories.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ── Animated category card (editorial style) ─────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final int index;
  const _CategoryCard({required this.category, required this.index});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
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

    // Staggered entrance: later cards wait longer, capped at 480 ms
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
    final screenW = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(ShopsList(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
        )),
      ),
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Full-width image ─────────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: SizedBox(
                    height: screenW,
                    width: double.infinity,
                    child: widget.category.image.isNotEmpty
                        ? _categoryImage(widget.category.image, screenW)
                        : _placeholder(screenW),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Text section slides up after image ───────────────────────
                SlideTransition(
                  position: _txtSlideAnim,
                  child: FadeTransition(
                    opacity: _txtFadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          widget.category.name,
                          style: AppTextStyles.displayMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.category.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.stone,
                            height: 1.75,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'Explore Collection',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.terracottaLight,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              size: 13,
                              color: AppColors.terracottaLight,
                            ),
                          ],
                        ),
                      ],
                      ),   // Column
                    ),     // Padding
                  ),       // FadeTransition
                ),         // SlideTransition

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

  Widget _categoryImage(String url, double size) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size));
    }
    return Image.network(url, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(size));
  }

  Widget _placeholder(double size) => Container(
        color: AppColors.surface,
        child: const Center(
          child: Text(
            '✦',
            style: TextStyle(color: AppColors.stone, fontSize: 34),
          ),
        ),
      );
}

