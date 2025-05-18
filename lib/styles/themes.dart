import 'package:chefoo/commons.dart';
import 'colors.dart';
import 'text_style.dart'; // Import the text styles

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
    textTheme: TextTheme(
      // Use the AppTextStyles as base styles and enhance with colors
      displayLarge: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
      headlineLarge:
          AppTextStyles.headline1.copyWith(color: AppColors.textPrimary),
      headlineMedium:
          AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
      headlineSmall:
          AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      bodyMedium: AppTextStyles.body.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: AppTextStyles.detail.copyWith(color: AppColors.textSecondary),
      labelLarge: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
      labelMedium:
          AppTextStyles.detail.copyWith(color: AppColors.textSecondary),
      labelSmall:
          AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    ),
    appBarTheme: AppBarTheme(
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headline3.copyWith(
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: kRadius30),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.button.copyWith(color: AppColors.surface),
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
          const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        ),
        minimumSize: WidgetStateProperty.all<Size>(const Size(168, 48)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.button.copyWith(
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
    progressIndicatorTheme: ProgressIndicatorThemeData(
      borderRadius: kRadius30,
      color: AppColors.primary, // The primary color of the indicator
      linearTrackColor:
          AppColors.surface, // Background color for linear indicators
      refreshBackgroundColor: AppColors.surface,
      linearMinHeight: 5.0, // Make the progress bar taller
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
  // You can follow the same pattern for dark theme
  return ThemeData();
}
