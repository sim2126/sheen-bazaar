import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Matches website easing [0.22, 1, 0.36, 1]
const _kCurve = Cubic(0.22, 1, 0.36, 1);

/// Full-screen navigation overlay triggered by the hamburger icon.
/// Matches the website's mobile menu aesthetic: large Cormorant text on
/// a near-opaque walnutDeep background, items staggered in on open.
class HamburgerMenu extends StatefulWidget {
  final bool isGuest;
  final int cartCount;
  final VoidCallback onClose;
  final VoidCallback onSearch;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onAI;
  final VoidCallback onAuthAction; // Sign In or Sign Out

  const HamburgerMenu({
    super.key,
    required this.isGuest,
    required this.cartCount,
    required this.onClose,
    required this.onSearch,
    required this.onCart,
    required this.onOrders,
    required this.onAI,
    required this.onAuthAction,
  });

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Each item gets its own staggered interval window
  Animation<double> _stagger(int index) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (index * 0.08).clamp(0.0, 0.6),
          (index * 0.08 + 0.45).clamp(0.1, 1.0),
          curve: _kCurve,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF81A130A), // walnutDeep at ~97% opacity
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar: brand name + close ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeTransition(
                    opacity: _stagger(0),
                    child: Text(
                      'Sheen Bazaar',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        color: AppColors.stone,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.stone,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 52),

              // ── Navigation items ─────────────────────────────────────────
              _NavItem(
                animation: _stagger(1),
                label: 'Home',
                activeColor: AppColors.terracotta,
                onTap: widget.onClose,
              ),
              _NavItem(
                animation: _stagger(2),
                label: 'Search',
                onTap: widget.onSearch,
              ),
              _NavItem(
                animation: _stagger(3),
                label: 'Cart',
                badge: widget.cartCount > 0 ? '${widget.cartCount}' : null,
                onTap: widget.onCart,
              ),
              _NavItem(
                animation: _stagger(4),
                label: 'My Orders',
                locked: widget.isGuest,
                onTap: widget.onOrders,
              ),
              _NavItem(
                animation: _stagger(5),
                label: 'AI',
                locked: widget.isGuest,
                onTap: widget.onAI,
              ),

              const Spacer(),

              // ── Ornamental divider ───────────────────────────────────────
              FadeTransition(
                opacity: _stagger(6),
                child: Row(
                  children: [
                    Container(width: 32, height: 1, color: AppColors.border),
                    const SizedBox(width: 10),
                    Text('✦',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.border)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Auth action ──────────────────────────────────────────────
              FadeTransition(
                opacity: _stagger(7),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(_stagger(7)),
                  child: GestureDetector(
                    onTap: widget.onAuthAction,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        widget.isGuest ? 'Sign In' : 'Sign Out',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.stone,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual navigation item ────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final Color activeColor;
  final String? badge;
  final bool locked;
  final VoidCallback onTap;

  const _NavItem({
    required this.animation,
    required this.label,
    this.activeColor = AppColors.cream,
    this.badge,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 52,
                    fontWeight: FontWeight.w400,
                    color: activeColor,
                    letterSpacing: 0.5,
                    height: 1.15,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.cream, fontSize: 11),
                    ),
                  ),
                ],
                if (locked) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.stone,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
