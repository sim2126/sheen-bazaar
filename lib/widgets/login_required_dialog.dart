import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet prompting the guest to log in or sign up.
/// Navigates to [LoginPage] with [returnAfterLogin] = true so the
/// user is returned to the current page after authenticating.
Future<void> showLoginRequiredDialog(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.walnutDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.stone, size: 24),
          ),
          const SizedBox(height: 16),

          Text('Sign in to continue', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text(
            'You need an account to do that.\nIt only takes a minute to get started.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.stone, height: 1.6),
          ),

          const SizedBox(height: 8),
          Text('✦', style: AppTextStyles.caption),
          const SizedBox(height: 20),

          // Login CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(returnAfterLogin: true)),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.terracotta,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Login', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 10),

          // Register CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(
                      returnAfterLogin: true,
                      initialMode: LoginMode.register,
                    )),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Create Account', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    ),
  );
}
