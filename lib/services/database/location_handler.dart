import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../commons.dart';
import '../../constants.dart';

class LocationHandler {
  static Future<void> initializeLocation(BuildContext context) async {
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
    
    locationService.locationChangedStream.listen((position) {
      print('Location changed significantly, fetching new places');
      fetchNearbyPlaces(context, position);
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
}