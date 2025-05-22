// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
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

  // LIGHT THEME COLORS
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

  // ENHANCED DARK THEME COLORS
  // iOS-inspired dark theme colors
  static const darkBackground = Color(0xFF121214); // Slightly bluer for iOS feel
  static const darkSurface = Color(0xFF1C1C1E); // iOS dark mode card color
  static const darkCard = Color(0xFF2C2C2E); // iOS dark mode elevated surface
  static const darkElevated = Color(0xFF3A3A3C); // Secondary elevation

  // Text colors for dark theme - better contrast ratios
  static const darkTextPrimary = Color(0xFFFEFEFE); // Off-white for better eye comfort
  static const darkTextSecondary = Color(0xFFAEAEB2); // iOS secondary text color
  static const darkTextTertiary = Color(0xFF636366); // iOS tertiary text color

  // Dark theme dividers and borders
  static const darkDivider = Color(0xFF38383A); // iOS-style separators

  // Status colors
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF2196F3);
  static const warning = Color(0xFFFFEB3B);
  static const error = Color(0xFFE53935);

  // iOS-style status colors
  static const iosSuccess = Color(0xFF30D158);
  static const iosInfo = Color(0xFF0A84FF);
  static const iosWarning = Color(0xFFFFD60A);
  static const iosError = Color(0xFFFF453A);

  // Match gradient
  static const matchGradientStart = Color(0xFFFF416C);
  static const matchGradientEnd = Color(0xFFFF4B2B);

  // Dark mode match gradient
  static const darkMatchGradientStart = Color(0xFFFF5483);
  static const darkMatchGradientEnd = Color(0xFFFF6242);

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

  // Dark mode match gradient
  static LinearGradient get darkMatchGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      darkMatchGradientStart,
      darkMatchGradientEnd,
    ],
  );

  // Get appropriate success color based on platform and theme
  static Color getSuccessColor(bool isDarkMode) {
    if (Platform.isIOS) {
      return isDarkMode ? iosSuccess : iosSuccess;
    }
    return success;
  }

  // Get appropriate error color based on platform and theme
  static Color getErrorColor(bool isDarkMode) {
    if (Platform.isIOS) {
      return isDarkMode ? iosError : iosError;
    }
    return error;
  }
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

  // Dark mode shadows - more subtle
  static List<BoxShadow> get darkSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get darkMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 6,
      spreadRadius: 0,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get darkLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get darkButton => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 6,
      spreadRadius: 0,
      offset: const Offset(0, 3),
    ),
  ];

  // Get the appropriate shadow based on brightness
  static List<BoxShadow> getShadow(BoxShadowType type, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    switch (type) {
      case BoxShadowType.small:
        return isDark ? darkSmall : small;
      case BoxShadowType.medium:
        return isDark ? darkMedium : medium;
      case BoxShadowType.large:
        return isDark ? darkLarge : large;
      case BoxShadowType.button:
        return isDark ? darkButton : button;
    }
  }
}

enum BoxShadowType { small, medium, large, button }

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
  // Light theme styles
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

  // Dark theme styles - with appropriate dark mode colors
  static TextStyle get darkHeadline1 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkHeadline2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkHeadline3 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkSubtitle1 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkSubtitle2 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkBody1 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkBody2 => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextPrimary,
  );

  static TextStyle get darkCaption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.darkTextSecondary,
  );

  // Get the appropriate text style based on brightness
  static TextStyle getStyle(TextStyleType type, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    switch (type) {
      case TextStyleType.headline1:
        return isDark ? darkHeadline1 : headline1;
      case TextStyleType.headline2:
        return isDark ? darkHeadline2 : headline2;
      case TextStyleType.headline3:
        return isDark ? darkHeadline3 : headline3;
      case TextStyleType.subtitle1:
        return isDark ? darkSubtitle1 : subtitle1;
      case TextStyleType.subtitle2:
        return isDark ? darkSubtitle2 : subtitle2;
      case TextStyleType.body1:
        return isDark ? darkBody1 : body1;
      case TextStyleType.body2:
        return isDark ? darkBody2 : body2;
      case TextStyleType.caption:
        return isDark ? darkCaption : caption;
      case TextStyleType.button:
        return button; // Button color is set by the button style
      case TextStyleType.appLogo:
        return appLogo;
      case TextStyleType.appTagline:
        return appTagline;
    }
  }
}

enum TextStyleType {
  headline1,
  headline2,
  headline3,
  subtitle1,
  subtitle2,
  body1,
  body2,
  caption,
  button,
  appLogo,
  appTagline
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
        color: AppColors.divider,
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

  static ThemeData get darkTheme {
    return ThemeData(
      // Color scheme
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onBackground: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        error: Platform.isIOS ? AppColors.iosError : AppColors.error,
        // iOS-specific color adjustments
        brightness: Brightness.dark,
        outline: AppColors.darkDivider,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Typography with light colors - optimized for dark mode
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),

      // App bar - iOS style in dark mode
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.darkHeadline3,
        iconTheme: IconThemeData(
          color: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensures status bar is visible
      ),

      // Cards - iOS style
      cardTheme: CardTheme(
        elevation: 0, // iOS cards typically have no elevation in dark mode
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.darkDivider, width: 0.5), // Subtle border
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated buttons - iOS style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          elevation: 0, // iOS buttons typically have no elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined buttons - iOS style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      // Text buttons - iOS style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button.copyWith(
            color: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
          ),
        ),
      ),

      // Input decoration - iOS style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: AppColors.darkDivider, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: AppColors.darkDivider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(
            color: Platform.isIOS ? AppColors.iosError : AppColors.error,
            width: 1.0,
          ),
        ),
        labelStyle: TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: TextStyle(color: AppColors.darkTextTertiary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),

      // Bottom navigation bar - iOS style
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // No elevation in iOS
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Divider theme - iOS style
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 0.5, // Thinner dividers in iOS
        space: 1,
      ),

      // Chip theme - iOS style
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog theme - iOS style
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // iOS uses slightly smaller rounding
        ),
        elevation: 0,
        backgroundColor: AppColors.darkCard,
        titleTextStyle: AppTextStyles.darkHeadline3,
        contentTextStyle: TextStyle(color: AppColors.darkTextSecondary),
      ),

      // Bottom sheet theme - iOS style
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), // iOS uses larger rounding for sheets
            topRight: Radius.circular(20),
          ),
        ),
        elevation: 0, // No elevation in iOS
      ),

      // Switch theme - iOS style
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Platform.isIOS ? AppColors.iosSuccess : AppColors.primary;
          }
          return AppColors.darkElevated;
        }),
      ),

      // Slider theme - iOS style
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.darkElevated,
        thumbColor: Colors.white,
        overlayColor: AppColors.primary.withOpacity(0.2),
        valueIndicatorColor: AppColors.darkCard,
        valueIndicatorTextStyle: TextStyle(color: AppColors.darkTextPrimary),
      ),

      // Icon theme - iOS style
      iconTheme: IconThemeData(
        color: AppColors.darkTextPrimary,
      ),
      primaryIconTheme: IconThemeData(
        color: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
      ),

      // CupertinoTheme for native iOS elements
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
        barBackgroundColor: AppColors.darkSurface,
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: Platform.isIOS ? AppColors.iosInfo : AppColors.primary,
          textStyle: TextStyle(color: AppColors.darkTextPrimary),
          actionTextStyle: TextStyle(color: Platform.isIOS ? AppColors.iosInfo : AppColors.primary),
          dateTimePickerTextStyle: TextStyle(color: AppColors.darkTextPrimary),
          navActionTextStyle: TextStyle(color: Platform.isIOS ? AppColors.iosInfo : AppColors.primary),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
          navTitleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          pickerTextStyle: TextStyle(color: AppColors.darkTextPrimary),
          tabLabelTextStyle: TextStyle(color: AppColors.darkTextSecondary),
        ),
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

  static BoxDecoration get darkGradientBackground => BoxDecoration(
    gradient: AppColors.darkPrimaryGradient,
  );

  static BoxDecoration get surfaceCard => BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: AppShadows.small,
  );

  static BoxDecoration get darkSurfaceCard => BoxDecoration(
    color: AppColors.darkCard,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: AppShadows.darkSmall,
  );

  static BoxDecoration get profileImageAvatar => BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 4),
    boxShadow: AppShadows.medium,
  );

  static BoxDecoration get darkProfileImageAvatar => BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.darkBackground, width: 4),
    boxShadow: AppShadows.darkMedium,
  );

  static BoxDecoration get roundedButton => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: AppShadows.button,
  );

  static BoxDecoration get darkRoundedButton => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: AppShadows.darkButton,
  );

  // Get the appropriate decoration based on brightness
  static BoxDecoration getDecoration(DecorationStyle style, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    switch (style) {
      case DecorationStyle.gradientBackground:
        return isDark ? darkGradientBackground : gradientBackground;
      case DecorationStyle.surfaceCard:
        return isDark ? darkSurfaceCard : surfaceCard;
      case DecorationStyle.profileImageAvatar:
        return isDark ? darkProfileImageAvatar : profileImageAvatar;
      case DecorationStyle.roundedButton:
        return isDark ? darkRoundedButton : roundedButton;
    }
  }
}

enum DecorationStyle {
  gradientBackground,
  surfaceCard,
  profileImageAvatar,
  roundedButton
}

