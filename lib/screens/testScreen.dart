import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../services/location.dart';
import '../services/maps.dart';
import '../services/popular_times.dart';  // Add this import
import '../models/restaurant.dart';
import '../widgets/base_layout.dart'; 
import '../widgets/restaurant_list.dart';
import 'map_view_screen.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({Key? key}) : super(key: key);

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
  List<Place> _places = [];
  Position? _lastFetchPosition;
  bool _mounted = true;

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
      _lastFetchPosition = newPosition;
      Future.microtask(() => _fetchNearbyPlaces());
    }
  }

  bool _shouldFetchNewPlaces(Position newPosition) {
    if (_lastFetchPosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastFetchPosition!.latitude,
      _lastFetchPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance > 500;  // Fetch new places if moved more than 500m
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

      await Future.delayed(const Duration(milliseconds: 100)); // Add small delay
      if (!mounted) return;

      print('Using location: ${position.latitude}, ${position.longitude}');

      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: apiKey,
      );

      if (response.success && response.data != null) {
        final updatedPlaces = [...response.data!];
        
        for (var place in updatedPlaces) {
          try {
            final popularTimesResponse = await http.get(
              Uri.parse('${PopularTimesService.baseUrl}/api/populartimes/${place.id}'),
            );

            if (popularTimesResponse.statusCode == 200) {
              final data = json.decode(popularTimesResponse.body);
              if (data['populartimes'] != null) {
                place.updatePopularTimes(
                  List<Map<String, dynamic>>.from(data['populartimes'])
                );
              }
            }
          } catch (e) {
            print('Error fetching popular times for ${place.name}: $e');
          }
        }

        if (mounted) {
          setState(() {
            _places = updatedPlaces;
          });
        }
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
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, _) {
        return Scaffold(
          body: RestaurantList(
            places: _places,
            isLoading: _isLoading,
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'mapView',
            child: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapViewScreen(places: _places),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

