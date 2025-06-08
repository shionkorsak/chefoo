import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/widgets/rate_popup.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/rating/rating_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/main_screen.dart';
import 'package:chefoo/commons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_controller.dart';
import 'package:chefoo/widgets/ai_input_field.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';
import 'package:chefoo/screens/main/other_recom_screen.dart';
import 'package:chefoo/screens/history/history_screen.dart';
import 'package:chefoo/widgets/cards/history_list.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/widgets/cards/restaurant_meal.dart';


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
        final overlay = Overlay.of(context);
        late OverlayEntry entry;

        entry = OverlayEntry(
          builder: (context) => Positioned(
            left: 20,
            right: 20,
            bottom: 90,
            child: RatePopup(
              restaurantName: ratingSession.restaurantName ?? 'a place',
              onDismissed: () => entry.remove(),
            ),
          ),
        );

        overlay.insert(entry);
      });
    }
  }

  Widget _buildChefoosPick(RecommendedProvider recommendedProvider) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedProvider.recommended.isEmpty) {
      return const Text("No recommendation found.", style: AppTextStyles.body);
    }

    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    final place = recommendedPlaces[0];

    if (position != null) {
      final distance = calculateGeoDistance(
        position.latitude, position.longitude, place.lat, place.lng);
      place.walkingDistance = distance / 1000;
    }

    return RestaurantCardHorizontal(
      place: recommendedPlaces[0],
      isLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
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
          final position = locationService.currentPosition;
          if (position != null && recommendedProvider.enriched.isNotEmpty) {
            for (var place in recommendedProvider.enriched) {
              final distance = calculateGeoDistance(position.latitude, position.longitude, place.lat, place.lng);
              place.walkingDistance = distance / 1000;
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AIInputField(onSubmitted: (text) => onAIQuerySubmitted(text)),
                  if (aiQuery.isNotEmpty && aiGeneratedResults.isNotEmpty)
                    ...aiGeneratedResults.map((place) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RestaurantMealCard(place: place, meals: [], isLoading: false),
                    )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Animate(
                          target: 0.0,
                          effects: [ShakeEffect(duration: Duration(milliseconds: 500), hz: 4, offset: Offset(8, 0))],
                          child: Text("Chefoo’s Pick", style: AppTextStyles.headline1.copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(height: 12),
                        if (aiQuery.isNotEmpty)
                          Column(
                            children: [
                              SizedBox(
                                height: 190,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: 3,
                                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final place = recommendedPlaces.isNotEmpty
                                        ? recommendedPlaces[index % recommendedPlaces.length]
                                        : null;

                                    return place != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: SizedBox(
                                              width: 320,
                                              child: RestaurantCardHorizontal(
                                                place: place,
                                                isLoading: false,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        if (!shouldShowGpsWarning)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                eventLocation.isNotEmpty
                                    ? Text(
                                        "You have class at $eventLocation soon, this place is on the way!",
                                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                      )
                                    : Text(
                                        "Check out this restaurant near you!",
                                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                      ),
                              ],
                            ),
                          ),
                        kGap8,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildChefoosPick(recommendedProvider),
                        ),
                        kGap20,
              
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              Text("Here are some options only for you!", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                              SizedBox(height: 1),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: resetInactivityTimer,
                          onPanDown: (_) => resetInactivityTimer(),
                          child: SizedBox(
                            height: 230,
                            child: RestaurantCardListHorizontal(
                              without: false,
                              places: recommendedProvider.enriched,
                              isLoading: isLoading,
                            ),
                          ),
                        ),
              
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Your Meals Lately...", style: AppTextStyles.headline2.copyWith(color: AppColors.primary)),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:(context) => HistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        kGap8,
                        HistoryList(),
                        SizedBox(height: 12),
                        Center(child: ClearPreferencesButton()),
                        const SizedBox(height: 90), // to prevent bottom content from being blocked by nav bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ClearPreferencesButton extends StatelessWidget {
  const ClearPreferencesButton({super.key});

  Future<void> clearRecommendationPrefs(BuildContext context) async {
    final uid = AuthService().getCurrentUserUID() ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${uid}_recommended_entries');

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
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
    );
  }
}
