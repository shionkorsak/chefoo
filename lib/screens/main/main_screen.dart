import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/mainscreen.dart';
import 'package:chefoo/commons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_controller.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:chefoo/screens/profile/profile.dart';
import 'package:chefoo/widgets/ai_input_field.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';
import 'package:chefoo/screens/main/other_recom_screen.dart';
import 'package:chefoo/screens/history/history_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends MainController {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildChefoosPick(RestaurantProvider restaurantProvider) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedPlaces.isEmpty) {
      return const Text(
        "No recommendation found.",
        style: AppTextStyles.body,
      );
    }

    return RestaurantCardHorizontal(
      place: recommendedPlaces[0],
      isLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainProvider = Provider.of<MainScreenProvider>(context);
    if (shouldShowGpsWarning) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 20),
              Text("GPS is off...", style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Optional: trigger GPS permission or refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: kRadius15),
                ),
                child: const Text("Enable GPS", style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<LocationService, RestaurantProvider>(
        builder: (context, locationService, restaurantProvider, _) { 
          return SafeArea(
            child: Padding(
              padding: kPadd20,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    const AIInputField(),
                    kGap20,
                    // Chefoo’s Pick
                    if (!shouldShowGpsWarning)
                      Animate(
                        target: 0.0,
                        effects: [
                          ShakeEffect(
                            duration: Duration(milliseconds: 500),
                            hz: 4,
                            offset: Offset(8, 0),
                          ),
                        ],
                        child: Text(
                          "Chefoo’s Pick",
                          style: AppTextStyles.headline1.copyWith(color: AppColors.primary),
                        ),
                      ),
                    kGap5,
                    eventLocation.isNotEmpty
                      ? Text(
                          "You have class at $eventLocation soon, this place is on the way!",
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        )
                      : Text(
                          "Check out this restaurant near you!",
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                    kGap8,
                    _buildChefoosPick(restaurantProvider),
                    kGap20,
          
                    // Other Recommendations (auto-scroll carousel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Other Recommendations", style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherRecomScreen(places: mainProvider.recommendations),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    kGap5,
                    Text("Here are some options only for you!", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    kGap8,
                    GestureDetector(
                      onTap: resetInactivityTimer,
                      onPanDown: (_) => resetInactivityTimer(),
                      child: SizedBox(
                        height: 270,
                        child: RestaurantCardListHorizontal(
                            without: false,
                            places: restaurantProvider.places,
                            isLoading: isLoading,
                        ),
                      ),
                    ),
                    kGap20,
          
                    // Your Meals Lately (static list)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Your Meals Lately...", style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryScreen(places: mainProvider.recentMeals),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    kGap8,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        height: 270,
                        child: RestaurantCardListHorizontal(
                            without: false,
                            places: mainProvider.recentMeals,
                            isLoading: mainProvider.isLoading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}