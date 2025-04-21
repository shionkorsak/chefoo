import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../services/location.dart';
import '../services/maps.dart';
import '../models/restaurant.dart';
import '../widgets/base_layout.dart'; 
import '../widgets/restaurant_list.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;

      if (position == null) {
        throw Exception('Location not available');
      }

      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: apiKey,
      );

      if (response.success && response.data != null) {
        for (var place in response.data!) {
          try {
            final popularTimesResponse = await http.get(
              Uri.parse('http://localhost:3001/api/populartimes/${place.id}'),
            );
            
            print('Popular times response status: ${popularTimesResponse.statusCode}');
            print('Popular times response body: ${popularTimesResponse.body}');

            if (popularTimesResponse.statusCode == 200) {
              final data = json.decode(popularTimesResponse.body);
              if (data['populartimes'] != null) {
                print('Found popular times data for ${place.name}');
                place.updatePopularTimes(
                  List<Map<String, dynamic>>.from(data['populartimes'])
                );
              } else {
                print('No popular times data available for ${place.name}');
              }
            } else {
              print('Error getting popular times: ${popularTimesResponse.statusCode}');
            }
          } catch (e) {
            print('Error fetching popular times for ${place.name}: $e');
          }
        }
      }

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _places = response.data!;
        }
      });
    } catch (e) {
      print('Error fetching nearby places: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RestaurantList(
      places: _places,
      isLoading: _isLoading,
    );
  }
}
