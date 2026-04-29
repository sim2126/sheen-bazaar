import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_router.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SheenBazaarApp());
}

class SheenBazaarApp extends StatelessWidget {
  const SheenBazaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sheen Bazaar',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.terracotta,
            brightness: Brightness.dark,
          ).copyWith(
            surface: AppColors.surface,
            primary: AppColors.terracotta,
            onPrimary: AppColors.cream,
            secondary: AppColors.gold,
            onSecondary: AppColors.cream,
          ),
          scaffoldBackgroundColor: AppColors.walnut,
          textTheme: GoogleFonts.nunitoTextTheme().copyWith(
            displayLarge: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontWeight: FontWeight.w500,
              color: AppColors.cream,
              letterSpacing: 1.0,
            ),
            headlineMedium: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.cream,
              letterSpacing: 0.3,
            ),
            bodyLarge: GoogleFonts.nunito(
              fontSize: 18,
              color: AppColors.cream,
              height: 1.6,
            ),
            bodyMedium: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.cream,
              height: 1.5,
            ),
            bodySmall: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.stone,
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.walnut,
            foregroundColor: AppColors.cream,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.cream,
              letterSpacing: 1.8,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cream,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
            ),
            labelStyle: GoogleFonts.nunito(color: AppColors.stone),
            hintStyle: GoogleFonts.nunito(color: AppColors.stone),
            prefixIconColor: AppColors.stone,
            suffixIconColor: AppColors.stone,
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.border,
            thickness: 1,
          ),
          iconTheme: const IconThemeData(color: AppColors.cream),
          cardTheme: CardThemeData(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.walnutDeep,
            selectedItemColor: AppColors.terracotta,
            unselectedItemColor: AppColors.stone,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
          useMaterial3: true,
        ),
        home: const AppRouter(),
      ),
    );
  }
}
