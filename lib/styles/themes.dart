import 'package:flutter_skeleton/commons.dart';
import 'colors.dart';

ThemeData get lightTheme {
  return ThemeData(
    fontFamily: 'Helvetica',
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: const CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      color: AppColors.surface,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary),
      headlineLarge: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary),
      headlineMedium: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      headlineSmall: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      bodyLarge: TextStyle(
          fontFamily: 'Helvetica', fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 14,
          color: AppColors.textSecondary),
      bodySmall: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 12,
          color: AppColors.textSecondary),
      labelLarge: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      labelSmall: TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 10,
          color: AppColors.textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontFamily: 'Helvetica',
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: kRadius30),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.surface,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary;
          }
          return AppColors.primary;
        }),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.surface),
        overlayColor: WidgetStateProperty.all<Color>(AppColors.secondary),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.only(
            left: 35,
            right: 35,
            top: 15,
            bottom: 15,
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.primary),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.all<Color>(AppColors.secondary),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.surface,
      onSecondary: AppColors.surface,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.surface,
    ),
  );
}

///Expand darkTheme to meet your needs
ThemeData get darkTheme {
  return ThemeData();
}
