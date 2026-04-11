import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../customer/customer_home.dart';
import '../shop_owner/shop_dashboard.dart';
import '../admin/admin_panel.dart';

enum LoginMode { login, register }

class LoginPage extends StatefulWidget {
  final bool returnAfterLogin;
  final LoginMode initialMode;
  const LoginPage({
    super.key,
    this.returnAfterLogin = false,
    this.initialMode = LoginMode.login,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late final PageController _pageController;

  String _role = 'customer';
  bool _loading = false;
  int _currentPage = 0;
  bool _obscurePass = true;

  bool get _isLogin => _currentPage == 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialMode == LoginMode.login ? 0 : 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    final formKey = _isLogin ? _loginFormKey : _registerFormKey;
    if (!formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'role': _role,
          'createdAt': Timestamp.now(),
        });
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final role = doc.data()?['role'];

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminPanel()));
      } else if (role == 'shop_owner') {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ShopDashboard()));
      } else {
        if (widget.returnAfterLogin) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const CustomerHome()));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.code)),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.terracotta),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.surface),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'email-already-in-use': return 'This email is already registered. Try logging in.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Brand header ───────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/chinar_leaf.png',
                          color: AppColors.terracottaLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sheen Bazaar',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cream,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('✦', style: AppTextStyles.caption),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Login / Register toggle ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.walnutDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _toggleBtn('Login', 0),
                    _toggleBtn('Register', 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── PageView of forms ──────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildLoginForm(),
                  _buildRegisterForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _label('Email'),
            _field(
              controller: _emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            _label('Password'),
            _passwordField(),
            const SizedBox(height: 20),
            _submitButton(),
            const SizedBox(height: 12),
            _switchHint(prompt: "Don't have an account?", label: 'Register', toPage: 1),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _label('Full Name'),
            _field(
              controller: _nameCtrl,
              hint: 'Your full name',
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            _label('Phone Number'),
            _field(
              controller: _phoneCtrl,
              hint: '9876543210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v!.isEmpty) return 'Phone is required';
                if (v.length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            _label('Email'),
            _field(
              controller: _emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            _label('Password'),
            _passwordField(),
            _label('I am a'),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  _roleChip(
                    label: 'Customer',
                    icon: const Icon(LucideIcons.shoppingBag, size: 24),
                    value: 'customer',
                  ),
                  const SizedBox(width: 12),
                  _roleChip(
                    label: 'Artisan / Shop Owner',
                    icon: const Icon(LucideIcons.palette, size: 24),
                    value: 'shop_owner',
                  ),
                ],
              ),
            ),
            _submitButton(),
            const SizedBox(height: 12),
            _switchHint(prompt: 'Already have an account?', label: 'Login', toPage: 0),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.terracotta,
          disabledBackgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _loading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(color: AppColors.cream, strokeWidth: 2),
              )
            : Text(
                _isLogin ? 'Login' : 'Create Account',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
      ),
    );
  }

  Widget _switchHint({
    required String prompt,
    required String label,
    required int toPage,
  }) {
    return Center(
      child: TextButton(
        onPressed: () => _goToPage(toPage),
        child: Text(
          '$prompt $label',
          style: AppTextStyles.caption.copyWith(color: AppColors.terracottaLight),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, int page) {
    final active = _currentPage == page;
    return Expanded(
      child: GestureDetector(
        onTap: () => _goToPage(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.terracotta : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: active ? AppColors.cream : AppColors.stone,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip({
    required String label,
    required Widget icon,
    required String value,
  }) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.terracotta : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.terracotta : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Theme(
                data: ThemeData(
                  iconTheme: IconThemeData(
                    color: selected ? AppColors.cream : AppColors.stoneLight,
                  ),
                ),
                child: icon,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.cream : AppColors.stoneLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.stoneLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passCtrl,
        obscureText: _obscurePass,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.cream),
        validator: (v) {
          if (v!.isEmpty) return 'Password is required';
          if (!_isLogin && v.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.stone),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.stone, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.stone, size: 20,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.terracotta),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.cream),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.stone),
          prefixIcon: Icon(icon, color: AppColors.stone, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.terracotta),
          ),
        ),
      ),
    );
  }
}
