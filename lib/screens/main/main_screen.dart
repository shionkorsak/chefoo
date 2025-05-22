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
  int _currentIndex = 0;

  final List<Place> mockListWheelPlaces = [
    Place(
      id: '1',
      name: 'Sunset Grill',
      address: '45 Sunset Blvd',
      rating: 4.3,
      distance: 0.5,
      lat: 25.0331,
      lng: 121.5641,
      pictureUrls: ['sample-photo-ref'],
      pictureCategory: 'default',
      tags: ['Grill'],
      walkingDistance: 300.0,
      reviews: [],
    ),
    Place(
      id: '2',
      name: 'Bubble Tea Express',
      address: '90 Boba Rd',
      rating: 4.6,
      distance: 0.2,
      lat: 25.0332,
      lng: 121.5642,
      pictureUrls: ['sample-photo-ref'],
      pictureCategory: 'default',
      tags: ['Drinks'],
      walkingDistance: 150.0,
      reviews: [],
    ),
    Place(
      id: '3',
      name: 'Veggie Delight',
      address: '12 Green St',
      rating: 4.4,
      distance: 0.4,
      lat: 25.0333,
      lng: 121.5643,
      pictureUrls: ['sample-photo-ref'],
      pictureCategory: 'default',
      tags: ['Vegetarian'],
      walkingDistance: 280.0,
      reviews: [],
    ),
    Place(
      id: '4',
      name: 'Ramen Rumble',
      address: '21 Broth Ave',
      rating: 4.8,
      distance: 0.7,
      lat: 25.0334,
      lng: 121.5644,
      pictureUrls: ['sample-photo-ref'],
      pictureCategory: 'default',
      tags: ['Ramen'],
      walkingDistance: 500.0,
      reviews: [],
    ),
    Place(
      id: '5',
      name: 'Curry Kingdom',
      address: '33 Spice Rd',
      rating: 4.5,
      distance: 0.6,
      lat: 25.0335,
      lng: 121.5645,
      pictureUrls: ['sample-photo-ref'],
      pictureCategory: 'default',
      tags: ['Curry'],
      walkingDistance: 460.0,
      reviews: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<MainScreenProvider>(context, listen: false).loadMockData();
    // });
  }

  Widget _buildChefoosPick(RestaurantProvider restaurantProvider) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurantProvider.places.isEmpty) {
      return const Text(
        "No recommendation found.",
        style: AppTextStyles.body,
      );
    }

    return RestaurantCardHorizontal(
      place: restaurantProvider.places[0],
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
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          switch (index) {
            case 1:
              setState(() => _currentIndex = index);
              toggleGps(); // temporary trigger
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
            default:
              setState(() => _currentIndex = index);
          }
        },
      ),
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
                    Text(
                      "You have class at NTHU Delta soon, this place is on the way!",
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