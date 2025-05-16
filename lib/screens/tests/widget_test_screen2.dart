import 'dart:convert';
import 'package:chefoo/screens/favorites.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/screens/map_view.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../providers/restaurant.dart';
import '../../commons.dart';

class WidgetTestScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Nearby Restaurants',
      child: RestaurantListContainer(),
    );
  }
}

class RestaurantListContainer extends StatefulWidget {
  @override
  _RestaurantListContainerState createState() =>
      _RestaurantListContainerState();
}

class _RestaurantListContainerState extends State<RestaurantListContainer> {
  bool _isLoading = false;
  static const double _minDistanceToRefresh = 500.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    final locationService =
        Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();

    if (mounted) {
      final position = locationService.currentPosition;
      if (position != null) {
        await _fetchNearbyPlaces(position);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = Provider.of<LocationService>(context);

    if (locationService.locationChangedSignificantly) {
      print("Location changed significantly, fetching new places");

      final position = locationService.currentPosition;
      if (position != null) {
        _fetchNearbyPlaces(position);
      }

      locationService.resetLocationChangedFlag();
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          'Fetching places for location: ${position.latitude}, ${position.longitude}');

      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider =
          Provider.of<RestaurantProvider>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey,
      );

      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');
        restaurantProvider.setPlaces(response.data!);
      } else {
        print('Failed to load places: ${response.message}');
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, RestaurantProvider>(
      builder: (context, locationService, restaurantProvider, _) {
        return Scaffold(
          // body: RestaurantList(
          //   places: restaurantProvider.places,
          //   isLoading: _isLoading,
          // ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              restaurantProvider.places.isNotEmpty
                  ? RestaurantCardHorizontal(
                      place: restaurantProvider.places[0])
                  : SizedBox(
                      height: 10,
                    ),
              Container(
                height: 220,
                child: RestaurantCardListHorizontal(
                    places: restaurantProvider.places, isLoading: _isLoading),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'favorites',
                child: const Icon(Icons.favorite),
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritesScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'mapView',
                child: const Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapViewScreen(
                        places: restaurantProvider.places,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
