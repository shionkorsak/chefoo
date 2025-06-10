import 'dart:math';

import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/main_screen.dart';
import 'package:chefoo/providers/meal_history.dart';
import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/history/history_screen.dart';
import 'package:chefoo/screens/main/other_recom_screen.dart';
import 'package:chefoo/widgets/ai_input_field.dart';
import 'package:chefoo/widgets/cards/history_list.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/widgets/cards/restaurant_card_vertical.dart';
import 'package:chefoo/widgets/rate_popup.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'main_controller.dart';

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

    if (widget.showWelcomeDialog &&
        !_dialogShown &&
        ratingSession.restaurantId != null) {
      _dialogShown = true;
      print('[MAIN] Showing rate.');
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      placeService.cleanupPlaceCache();

      final restaurantProvider =
          Provider.of<RestaurantProvider>(context, listen: false);
      restaurantProvider.notifyListeners();

      final mealHistoryProvider =
          Provider.of<MealHistoryProvider>(context, listen: false);
      mealHistoryProvider.fetchMeals();
    });
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

    final locationService =
        Provider.of<LocationService>(context, listen: false);
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
    final mainProvider = Provider.of<MainScreenProvider>(context);
    if (shouldShowGpsWarning) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off,
                  size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 20),
              Text("GPS is off...",
                  style: AppTextStyles.headline2
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Optional: trigger GPS permission or refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            final distance = calculateGeoDistance(
                position.latitude, position.longitude, place.lat, place.lng);

            place.walkingDistance = distance / 1000;
          }
        }

        return SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AIInputField(
                      onSubmitted: (text) => onAIQuerySubmitted(text),
                    ),
                    const SizedBox(height: 12),
                    if (isAILoading)  
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (aiGeneratedResults.isNotEmpty)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 24,
                              child: RestaurantCardHorizontal(
                                place: aiGeneratedResults[0], // Only show the first result
                                isLoading: false,
                              ),
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
                              effects: const [
                                ShakeEffect(
                                  duration: Duration(milliseconds: 500),
                                  hz: 4,
                                  offset: Offset(8, 0),
                                ),
                              ],
                              child: Text(
                                "Chefoo’s Pick",
                                style: AppTextStyles.headline1.copyWith(
                                    color: AppColors.primary, height: 1),
                              ),
                            ),
                            eventLocation.isNotEmpty
                                ? Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "You have ",
                                          style: AppTextStyles.detail,
                                        ),
                                        if (eventName.isNotEmpty)
                                          TextSpan(
                                            text: "$eventName",
                                            style: AppTextStyles.detail
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        if (eventName.isNotEmpty)
                                          TextSpan(
                                            text: " at ",
                                            style: AppTextStyles.detail,
                                          ),
                                        TextSpan(
                                          text: eventLocation,
                                          style: AppTextStyles.detail
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text:
                                              " soon, this place is on the way!",
                                          style: AppTextStyles.detail,
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    "Check out this restaurant near you!",
                                    style: AppTextStyles.detail,
                                  ),
                          ],
                        ),
                      ),
                    kGap8,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              Text("Other Spots",
                                  style: AppTextStyles.headline2
                                      .copyWith(color: AppColors.primary)),
                              IconButton(
                                icon: const Icon(Icons.chevron_right,
                                    color: AppColors.primary),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(24, 24),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  // final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
              
                                  // final Map<String, Place> uniquePlaces = {};
              
                                  // for (var place in restaurantProvider.routePlaces) {
                                  //   uniquePlaces[place.id] = place;
                                  // }
              
                                  // for (var place in restaurantProvider.places) {
                                  //   uniquePlaces[place.id] = place;
                                  // }
              
                                  // final List<Place> combinedPlaces = uniquePlaces.values
                                  //   .where((place) =>
                                  //     place.isOpenNow == true && place.rating > 0
                                  //   )
                                  //   .toList();
              
                                  // final displayPlaces2 = combinedPlaces.isNotEmpty
                                  //     ? Provider.of<RecommendedProvider>(context, listen: false).enriched
                                  //     : combinedPlaces;
              
                                  // print('Showing filtered places in Other Recommendations: ${displayPlaces2.length} valid places');
              
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OtherRecomScreen(
                                          places: enrichedPlaces),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text("Here are some options only for you!",
                              style: AppTextStyles.detail),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    GestureDetector(
                      onTap: resetInactivityTimer,
                      onPanDown: (_) => resetInactivityTimer(),
                      child: SizedBox(
                        height: 215,
                        child: Builder(
                          builder: (context) {
                            if (isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
              
                            if (enrichedPlaces.isEmpty) {
                              return const Center(
                                  child: Text('No restaurants found nearby'));
                            }
              
                            return ListView.separated(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: enrichedPlaces.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RestaurantCardVertical(
                                    place: enrichedPlaces[index]),
                              ),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Your Meals Lately...",
                              style: AppTextStyles.headline2
                                  .copyWith(color: AppColors.primary)),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: AppColors.primary),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(24, 24),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    HistoryList(),
                    SizedBox(height: 12),
                    // Center(child: ClearPreferencesButton()),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ClearPreferencesButton extends StatelessWidget {
  const ClearPreferencesButton({super.key});

  Future<void> clearRecommendationPrefs(BuildContext context) async {
    // final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
