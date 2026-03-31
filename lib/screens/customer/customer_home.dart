import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../utils/transitions.dart';
import 'shops_list.dart';
import 'cart_icon_button.dart';
import 'ai_assistant.dart';
import '../auth/login_page.dart';
import '../../widgets/login_required_dialog.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late Future<List<CategoryModel>> _categories;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _categories = CategoryService().getCategories();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sheen Bazaar'),
        actions: _isGuest ? _guestActions() : _loggedInActions(),
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          final categories = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _CategoryCard(category: categories[index]),
          );
        },
      ),
      floatingActionButton: _isGuest
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3D2B1F),
              icon: const Icon(Icons.login, color: Color(0xFFC9A55A)),
              label: const Text(
                'Sign In',
                style: TextStyle(
                  color: Color(0xFFC9A55A),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => showLoginRequiredDialog(context),
            )
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3D2B1F),
              icon: const Icon(LucideIcons.sparkles, color: Color(0xFFC9A55A), size: 20),
              label: const Text(
                'AI Assistant',
                style: TextStyle(
                  color: Color(0xFFC9A55A),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                fadeSlideRoute(const AiAssistant()),
              ),
            ),
    );
  }

  List<Widget> _guestActions() {
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.person_outline, color: Color(0xFFF5EDE0)),
        color: const Color(0xFFF5EDE0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) => Navigator.push(
          context,
          fadeSlideRoute(LoginPage(
            returnAfterLogin: true,
            initialMode: value == 'login' ? LoginMode.login : LoginMode.register,
          )),
        ),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'login',
            child: Row(
              children: const [
                Icon(Icons.login, size: 18, color: Color(0xFF3D2B1F)),
                SizedBox(width: 10),
                Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF3D2B1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'register',
            child: Row(
              children: const [
                Icon(Icons.person_add_outlined, size: 18, color: Color(0xFF3D2B1F)),
                SizedBox(width: 10),
                Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF3D2B1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _loggedInActions() {
    return [
      CartIconButton(),
      IconButton(
        icon: const Icon(Icons.logout, color: Color(0xFFF5EDE0)),
        onPressed: () => FirebaseAuth.instance.signOut(),
      ),
    ];
  }
}

// ── Category Card with press-scale animation ──
class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.94);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(ShopsList(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
        )),
      ),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.category.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFFEDE0CC)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0xCC1E1208),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.category.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
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
    );
  }
}
