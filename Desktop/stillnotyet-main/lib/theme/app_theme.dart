// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary gradient colors
  static const primary = Color(0xFFFF4458);
  static const primaryLight = Color(0xFFFF7A8A);
  static const primaryDark = Color(0xFFE5132A);

  // Secondary accent colors
  static const secondary = Color(0xFFFF7854);
  static const secondaryLight = Color(0xFFFF9D7D);
  static const secondaryDark = Color(0xFFE55934);

  // Tertiary colors for highlights and accents
  static const tertiary = Color(0xFF21D07C);
  static const tertiaryLight = Color(0xFF6FEEB3);
  static const tertiaryDark = Color(0xFF18A45F);

  // Background colors
  static const background = Color(0xFFFAFAFA);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFFF5F5F5);
  static const divider = Color(0xFFEEEEEE);

  // Text colors
  static const text = Color(0xFF212121);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textTertiary = Color(0xFFBDBDBD);

  // Status colors
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF2196F3);
  static const warning = Color(0xFFFFEB3B);
  static const error = Color(0xFFE53935);

  // Match gradient
  static const matchGradientStart = Color(0xFFFF416C);
  static const matchGradientEnd = Color(0xFFFF4B2B);

  // Core app gradients
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      secondary,
      primary.withOpacity(0.9),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static LinearGradient get darkPrimaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDark,
      secondaryDark,
      primaryDark.withOpacity(0.9),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // Match screen gradient
  static LinearGradient get matchGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      matchGradientStart,
      matchGradientEnd,
    ],
  );
}

class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double button = 30.0;
  static const double card = 16.0;
  static const double circle = 100.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTextStyles {
  static TextStyle get headline1 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline3 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle1 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle2 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get body1 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get body2 => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static TextStyle get appLogo => GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: 8.0,
    color: Colors.white,
    fontStyle: FontStyle.italic,
    shadows: [
      Shadow(
        blurRadius: 10.0,
        color: Colors.black.withOpacity(0.25),
        offset: const Offset(0, 4),
      ),
    ],
  );

  static TextStyle get appTagline => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    letterSpacing: 3.0,
    color: Colors.white.withOpacity(0.9),
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Color scheme
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        background: AppColors.background,
        surface: AppColors.surfaceLight,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // Typography
      textTheme: GoogleFonts.poppinsTextTheme(),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headline3,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          elevation: 3,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textTertiary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.textTertiary,
        thickness: 1,
        space: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: AppTextStyles.body2.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        elevation: 4,
        backgroundColor: AppColors.surfaceLight,
        titleTextStyle: AppTextStyles.headline3,
        contentTextStyle: AppTextStyles.body1,
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.body1,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: CircleBorder(),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.large),
            topRight: Radius.circular(AppRadius.large),
          ),
        ),
        elevation: 8,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.textTertiary,
        circularTrackColor: AppColors.textTertiary,
      ),
    );
  }
}

// Custom clipper for wave effect used in profile screens
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 40);
    var secondEndPoint = Offset(size.width, size.height);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom decoration for consistent gradient backgrounds
class AppDecorations {
  static BoxDecoration get gradientBackground => BoxDecoration(
    gradient: AppColors.primaryGradient,
  );

  static BoxDecoration get surfaceCard => BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: AppShadows.small,
  );

  static BoxDecoration get profileImageAvatar => BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 4),
    boxShadow: AppShadows.medium,
  );

  static BoxDecoration get roundedButton => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: AppShadows.button,
  );
}