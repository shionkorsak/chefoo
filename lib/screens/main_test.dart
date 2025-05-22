import 'dart:developer';

import 'package:chefoo/screens/profile/profile.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:chefoo/widgets/cards/favorite_list.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';

import '../commons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: const Column(
                children: [
                    RestaurantList(),
                    SizedBox(height: 100),
                    FavoriteList(),
                    SizedBox(height: 100)
                ],
            )
        ),
    );
  }
}

class RestaurantList extends StatefulWidget {
  const RestaurantList({super.key});

  @override
  State<RestaurantList> createState() => _RestaurantListState();
}

class _RestaurantListState extends State<RestaurantList> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    if(restaurantProvider.places.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final locationService = 
      Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();

    final position = locationService.currentPosition;
    if(position != null) {
      await _fetchandRecommend(position);
    }
    
  }

  Future<void> _fetchandRecommend(Position position) async {
    final placeService = 
      Provider.of<PlaceService>(context, listen: false);
    final restaurantProvider = 
      Provider.of<RestaurantProvider>(context, listen: false);

    final service = RecommendationService (
      placeService: placeService, 
      restaurantProvider: restaurantProvider
      );

    try {
      await service.fetchAndRecommendNearbyPlaces(position, context);
    } catch (e) {
      log('Error fetching recommendations: $e');
    } finally {
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = 
      Provider.of<LocationService>(context);
    final restaurantProvider = 
      Provider.of<RestaurantProvider>(context, listen: false);

    if(locationService.locationChangedSignificantly) {
      log('Location changed significantly, fetching new places');

      final position = locationService.currentPosition;
      if(position != null) {
        setState(() {
          _isLoading = true;
        });
        _fetchandRecommend(position);
      } else {
        log('position is null');
      }

      locationService.resetLocationChangedFlag();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, RestaurantProvider>(
      builder: (context, locationService, restaurantProvider, _) {
        return Column(
            children: [
              // TODO: search bar for AI
              SizedBox(height: 100),
              restaurantProvider.places.isNotEmpty
                ? RestaurantCardHorizontal(
                  place: restaurantProvider.places[0],
                  isLoading: _isLoading,
                  )
                : SizedBox(height: 10),
              SizedBox(height: 50),
              Container(
                height: 220,
                child: RestaurantCardListHorizontal(
                  // places: restaurantProvider.places.length > 1
                  //   ? restaurantProvider.places.sublist(1)
                  //   : restaurantProvider.places, 
                  places: restaurantProvider.places,
                  isLoading: _isLoading
                ),
              ),
            ],
        );
      },
    );
  }
}

