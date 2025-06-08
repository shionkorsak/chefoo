import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../commons.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationHandler {
  static Future<void> initializeLocation(BuildContext context) async {
    print('[LOCATION HANDLER]');
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();
    
    final position = locationService.currentPosition;
    if (position != null) {
      await fetchNearbyPlaces(context, position);
    }
    
    startLocationUpdates(context);
  }

  static Future<void> fetchNearbyPlaces(BuildContext context, Position position) async {
    try {
      print('Fetching places for location: ${position.latitude}, ${position.longitude}');
      
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      
      restaurantProvider.setLoading(true);
      
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');
        restaurantProvider.setPlaces(response.data!);
        
        restaurantProvider.updateCurrentPlaces(
          position.latitude,
          position.longitude,
          1000.0
        );
      } else {
        print('Failed to load places: ${response.message}');
        restaurantProvider.setError(response.message);
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      Provider.of<RestaurantProvider>(context, listen: false)
          .setError("Couldn't load restaurants");
    } finally {
      Provider.of<RestaurantProvider>(context, listen: false).setLoading(false);
    }
  }

  static void startLocationUpdates(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
    final subscription = locationService.locationChangedStream.listen((position) {
      restaurantProvider.updateCurrentPlaces(
        position.latitude,
        position.longitude,
        1000.0
      );
      
      final state = context.findAncestorStateOfType<State>();
      if (state?.mounted == true) {
        print('Location changed significantly, fetching new places');
        fetchNearbyPlaces(context, position);
      } else {
        print('Skipping fetchNearbyPlaces because widget is no longer mounted');
      }
    });
  }

  static Future<void> fetchNearbyPlacesAtCurrentLocation(BuildContext context) async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      if (locationService.currentPosition == null) {
        await locationService.getCurrentLocation();
      }
      
      final position = locationService.currentPosition;
      if (position != null) {
        print('Fetching places at current location: ${position.latitude}, ${position.longitude}');
        
        final placeService = Provider.of<PlaceService>(context, listen: false);
        final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
        
        restaurantProvider.setLoading(true);
        
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
        
        restaurantProvider.setLoading(false);
      } else {
        print('Could not get current location');
      }
    } catch (e) {
      print('Error in fetchNearbyPlacesAtCurrentLocation: $e');
      
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      restaurantProvider.setLoading(false);
    }
  }

  static Future<void> geocodeAddressAndFindRestaurants(
    BuildContext context, 
    String address
  ) async {
    try {
      final apiKey = MapsConstants.mapsKey;
      final encodedAddress = Uri.encodeComponent(address);
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedAddress'
        '&key=$apiKey'
      );
      
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Geocoding API error');
      }
      
      final data = json.decode(response.body);
      if (data['status'] != 'OK' || data['results'].isEmpty) {
        throw Exception('No location found for address');
      }
      
      final location = data['results'][0]['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      
      restaurantProvider.setLoading(true);
      
      final restaurantResponse = await placeService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radius: 1000.0,
        apiKey: apiKey,
      );
      
      if (restaurantResponse.success && restaurantResponse.data != null) {
        restaurantProvider.setPlaces(restaurantResponse.data!);
      } else {
        throw Exception(restaurantResponse.message);
      }
      
      restaurantProvider.setLoading(false);
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  static Future<void> geocodeAddressAndFetchRestaurants(
    BuildContext context, 
    String address
  ) async {
    try {
      final apiKey = MapsConstants.mapsKey;
      
      final encodedAddress = Uri.encodeComponent(address);
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedAddress'
        '&key=$apiKey'
      );
      
      final http.Response response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to geocode address');
      }
      
      final data = json.decode(response.body);
      
      if (data['status'] != 'OK' || data['results'].isEmpty) {
        throw Exception('No location found for: $address');
      }
      
      final location = data['results'][0]['geometry']['location'];
      final double lat = location['lat'];
      final double lng = location['lng'];
      
      print('Geocoded address to: $lat, $lng');
      
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final placeService = Provider.of<PlaceService>(context, listen: false);
      
      restaurantProvider.setLoading(true);
      
      final restaurantResponse = await placeService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radius: 1000.0,
        apiKey: apiKey,
      );
      
      if (restaurantResponse.success && restaurantResponse.data != null) {
        restaurantProvider.setPlaces(restaurantResponse.data!);
      } else {
        throw Exception(restaurantResponse.message);
      }
      
    } catch (e) {
      print('Error in geocodeAddressAndFetchRestaurants: $e');
      Provider.of<RestaurantProvider>(context, listen: false).setLoading(false);
      rethrow;
    } finally {
      Provider.of<RestaurantProvider>(context, listen: false).setLoading(false);
    }
  }
}