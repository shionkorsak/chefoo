import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/rating/rating_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/main_screen.dart';
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
  final bool showWelcomeDialog;
  const MainScreen({super.key, required this.showWelcomeDialog});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends MainController {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ratingSession = Provider.of<RatingSessionProvider>(context);

    if (widget.showWelcomeDialog && !_dialogShown && ratingSession.restaurantId != null) {
      _dialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Welcome Back"),
            content: Text("You've returned from Google Maps for ${ratingSession.restaurantName ?? 'a place'}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RatingScreen()),
                  );
                },
                child: const Text("Rate"),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildChefoosPick(RecommendedProvider recommendedProvider) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedProvider.recommended.isEmpty) {
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
      body: Consumer2<LocationService, RecommendedProvider>(
        builder: (context, locationService, recommendedProvider, _) { 
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
                    //[UNCOMMENT LATER]
                    _buildChefoosPick(recommendedProvider),
                    kGap20,
          
                    // Other Recommendations (auto-scroll carousel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Other Recommendations", style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                          onPressed: () {
                            final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
                            
                            final Map<String, Place> uniquePlaces = {};
                            
                            for (var place in restaurantProvider.routePlaces) {
                              uniquePlaces[place.id] = place;
                            }
                            
                            for (var place in restaurantProvider.places) {
                              uniquePlaces[place.id] = place;
                            }
                            
                            final List<Place> combinedPlaces = uniquePlaces.values.toList();
                            
                            print('Showing combined places in Other Recommendations: ${combinedPlaces.length} total');
                            print('(${restaurantProvider.routePlaces.length} route + ${restaurantProvider.places.length} nearby, ${combinedPlaces.length} unique)');
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherRecomScreen(places: combinedPlaces),
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
                          places: recommendedProvider.enriched,
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
                    ClearPreferencesButton()
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

class ClearPreferencesButton extends StatelessWidget {
  const ClearPreferencesButton({super.key});

  Future<void> clearRecommendationPrefs(BuildContext context) async {
    // final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final uid = AuthService().getCurrentUserUID() ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      '${uid}_recommended',
      '${uid}_enriched',
      '${uid}_lat',
      '${uid}_lng',
      '${uid}_timestamp',
    ];

    for (final key in keys) {
      await prefs.remove(key);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recommendation prefs cleared.')),
    );

    debugPrint('[DEBUG] Cleared preferences for user: $uid');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => clearRecommendationPrefs(context),
      icon: const Icon(Icons.delete_forever),
      label: const Text('Clear Recommendation Cache'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}