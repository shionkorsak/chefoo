import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_skeleton/constants.dart';
import 'package:flutter_skeleton/screens/map_view.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../providers/restaurant.dart';
import '../commons.dart';

class TestScreen extends StatelessWidget {
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
  _RestaurantListContainerState createState() => _RestaurantListContainerState();
}

class _RestaurantListContainerState extends State<RestaurantListContainer> {
  bool _isLoading = false;
  static const double _minDistanceToRefresh = 500.0; // meters

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();  // Changed from startLocationUpdates
    
    if (mounted) {
      final position = locationService.currentPosition;
      if (position != null) {
        await _fetchNearbyPlaces();  // Added await
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationService = Provider.of<LocationService>(context);
    final newPosition = locationService.currentPosition;
    
    if (newPosition != null && _shouldFetchNewPlaces(newPosition)) {
      Future.microtask(() => _fetchNearbyPlaces());
    }
  }

  bool _shouldFetchNewPlaces(Position newPosition) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final lastFetchPosition = locationService.lastFetchPosition;
    
    // If no last fetch position, we should fetch
    if (lastFetchPosition == null) return true;

    // Calculate distance moved since last fetch
    final distance = Geolocator.distanceBetween(
      lastFetchPosition.latitude,
      lastFetchPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // Fetch new places if moved more than minimum distance
    return distance > _minDistanceToRefresh;
  }

  Future<void> _fetchNearbyPlaces() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;

      if (position == null) {
        throw Exception('Location not available');
      }

      final apiKey = MapsConstants.mapsKey;
      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: apiKey,
      );

      if (response.success && response.data != null) {
        final provider = Provider.of<RestaurantProvider>(context, listen: false);
        provider.setPlaces(response.data!);
        // Update last fetch position using the proper setter method
        locationService.setLastFetchPosition(position);
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          body: RestaurantList(
            places: restaurantProvider.places, // Use places from provider instead of _places
            isLoading: _isLoading,
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'mapView',
            child: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapViewScreen(
                    places: restaurantProvider.places, // Use provider's places here too
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

