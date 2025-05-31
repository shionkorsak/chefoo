import 'dart:developer';
import 'dart:convert';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:chefoo/commons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/restaurant.dart';

class PreloadService {
  static Future<bool> preloadData(BuildContext context, [RestaurantProvider? providedRestaurantProvider]) async {
    print('Starting data preloading...');
    
    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);
      final calendarService = CalendarService();
      final restaurantProvider = providedRestaurantProvider ?? 
                                  Provider.of<RestaurantProvider>(context, listen: false);
      final calendarStateProvider = Provider.of<CalendarStateProvider>(context, listen: false);

      await _preloadNearbyPlaces(
        context,
        placeService,
        locationService, 
        restaurantProvider
      );
      
      await _preloadNextEventAndRoutePlaces(
        placeService, 
        calendarService,
        locationService,
        restaurantProvider,
        calendarStateProvider
      );
      
      print('Data preloading completed successfully');
      return true;
    } catch (e) {
      print('Error during data preloading: $e');
      return false;
    }
  }

  static Future<void> _preloadNearbyPlaces(
    BuildContext context,
    PlaceService placeService,
    LocationService locationService,
    RestaurantProvider restaurantProvider
  ) async {
    try {
      print('[PRELOAD GET NEARBY]');
      final position = locationService.currentPosition;
      if (position == null) {
        print('[PRELOAD] Current location not available for preloading');
        return;
      }

      print('[PRELOAD] Loading basic places data...');
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (response.success && response.data != null) {
        print('[PRELOAD] Successfully loaded ${response.data!.length} places');
        restaurantProvider.setPlaces(response.data!);
      } else {
        print('[PRELOAD] Failed to load places: ${response.message}');
      }

      /* 
      print('[PRELOAD] Preloading nearby places...');
      
      final recommendationService = RecommendationService(
        placeService: placeService, 
        restaurantProvider: restaurantProvider
        );

      final result = 
        await recommendationService
        .fetchAndRecommendNearbyPlaces(position, context);

      final recommendedPlaces = result['recommended'] ?? [];
      final enrichedPlaces = result['enriched'] ?? [];

      if (recommendedPlaces.isNotEmpty) {
        restaurantProvider.setRecommendedPlaces(recommendedPlaces);
        print('[PRELOAD] Stored ${recommendedPlaces.length} recommended places');
      } else {
        print('[PRELOAD] NO RECOMMENDATION???');
      }

      if (enrichedPlaces.isNotEmpty) {
        restaurantProvider.setPlaces(enrichedPlaces);
        print('[PRELOAD] Stored ${enrichedPlaces.length} enriched places');
      }
      */
    } catch (e) {
      print('Error preloading nearby places: $e');
    }
  }

  static Future<void> _preloadNextEventAndRoutePlaces(
    PlaceService placeService,
    CalendarService calendarService,
    LocationService locationService,
    RestaurantProvider restaurantProvider,
    CalendarStateProvider calendarStateProvider
  ) async {
    try {
      final eventResponse = await calendarService.getNextEvent();
      if (!eventResponse.success || eventResponse.data == null) {
        print('No upcoming events found for preloading route places');
        return;
      }

      final event = eventResponse.data!;
      print('Preloading route places for event: ${event.title}');
      
      calendarStateProvider.setNextEvent(event);

      if (event.location.isNotEmpty) {
        final coordinates = await _geocodeAddress(event.location);
        if (coordinates != null) {
          calendarStateProvider.setEventLocation(coordinates);
          
          await _preloadPlacesAlongRoute(
            placeService,
            locationService,
            restaurantProvider,
            coordinates
          );
        }
      }

      print('Event and route places preloaded successfully');
    } catch (e) {
      print('Error preloading event and route places: $e');
    }
  }
  
  static Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final apiKey = MapsConstants.mapsKey;
      if (apiKey.isEmpty) {
        throw Exception('Google Maps API Key not found');
      }

      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedAddress'
        '&key=$apiKey'
      );

      final client = http.Client();
      final response = await client.get(url);

      if (response.statusCode != 200) {
        throw Exception('Geocoding API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        throw Exception('No results found for this address');
      }

      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  static Future<void> _preloadPlacesAlongRoute(
    PlaceService placeService,
    LocationService locationService,
    RestaurantProvider restaurantProvider,
    LatLng destination
  ) async {
    try {
      final position = locationService.currentPosition;
      if (position == null) {
        print('Current location not available for route preloading');
        return;
      }

      print('Preloading places along route from (${position.latitude}, ${position.longitude}) to (${destination.latitude}, ${destination.longitude})');

      final Map<String, Place> allPlaces = {};
      
      final nearDestinationResponse = await placeService.getNearbyPlaces(
        lat: destination.latitude,
        lng: destination.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );

      if (nearDestinationResponse.success && nearDestinationResponse.data != null) {
        for (var place in nearDestinationResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${nearDestinationResponse.data!.length} places near destination');
      }
      
      final midLat = (position.latitude + destination.latitude) / 2;
      final midLng = (position.longitude + destination.longitude) / 2;
      
      final midpointResponse = await placeService.getNearbyPlaces(
        lat: midLat,
        lng: midLng,
        radius: 1500,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (midpointResponse.success && midpointResponse.data != null) {
        for (var place in midpointResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${midpointResponse.data!.length} places near route midpoint');
      }
      
      final distance = _calculateDistance(
        position.latitude, position.longitude,
        destination.latitude, destination.longitude
      );
      
      if (distance > 3.0) { 
        final quarterLat = position.latitude + (destination.latitude - position.latitude) * 0.25;
        final quarterLng = position.longitude + (destination.longitude - position.longitude) * 0.25;
        
        final quarterResponse = await placeService.getNearbyPlaces(
          lat: quarterLat,
          lng: quarterLng,
          radius: 1000,
          apiKey: MapsConstants.mapsKey,
        );
        
        if (quarterResponse.success && quarterResponse.data != null) {
          for (var place in quarterResponse.data!) {
            allPlaces[place.id] = place;
          }
          print('Loaded ${quarterResponse.data!.length} places at quarter point');
        }
        
        final threeQuarterLat = position.latitude + (destination.latitude - position.latitude) * 0.75;
        final threeQuarterLng = position.longitude + (destination.longitude - position.longitude) * 0.75;
        
        final threeQuarterResponse = await placeService.getNearbyPlaces(
          lat: threeQuarterLat,
          lng: threeQuarterLng,
          radius: 1000,
          apiKey: MapsConstants.mapsKey,
        );
        
        if (threeQuarterResponse.success && threeQuarterResponse.data != null) {
          for (var place in threeQuarterResponse.data!) {
            allPlaces[place.id] = place;
          }
          print('Loaded ${threeQuarterResponse.data!.length} places at three-quarter point');
        }
      }
      
      final places = allPlaces.values.toList();
      restaurantProvider.addPlaces(places);
      restaurantProvider.setRoutePlacesLoaded(true);
      
      final nearbyKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_2000';
      placeService.updateCacheWithRoutePlaces(nearbyKey, places);
      
      print('Total preloaded places along route: ${places.length}');
    } catch (e) {
      print('Error preloading places along route: $e');
    }
  }
}