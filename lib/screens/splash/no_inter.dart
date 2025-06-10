import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/services/connectivity_service.dart';
import 'package:chefoo/screens/splash/splash.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder for illustration
                Container(
                  width: 200,
                  height: 200,
                  color: AppColors.primary.withOpacity(0.2),
                  child: const Center(
                    child: Text(
                      '📶!',
                      style: TextStyle(fontSize: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NO INTERNET\nCONNECTION',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final connectivityService =
                        Provider.of<ConnectivityService>(context,
                            listen: false);

                    final hasInternet =
                        await connectivityService.checkConnectivity();
                    if (hasInternet && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
