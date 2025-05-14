import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:chefoo/commons.dart';
import 'package:chefoo/services/maps.dart';
import 'package:chefoo/services/location.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/providers/calendar_state.dart';

class PreloadService {
  
  static Future<void> preloadData(BuildContext context) async {
    print('Starting to preload application data...');
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
      
      await locationService.getCurrentLocation();
      
      int attempts = 0;
      while (locationService.currentPosition == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      
      final position = locationService.currentPosition;
      if (position == null) {
        print('Could not get current location for preloading');
        return;
      }
      
      print('Initial position: (${position.latitude}, ${position.longitude})');
      
      final Map<String, Place> allPlaces = {};
      
      print('Loading places near current location...');
      final nearCurrentResponse = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1500,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (nearCurrentResponse.success && nearCurrentResponse.data != null) {
        for (var place in nearCurrentResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${nearCurrentResponse.data!.length} places near current location');
      }
      
      print('Loading upcoming calendar event...');
      final calendarService = CalendarService();
      final eventResponse = await calendarService.getNextEvent();
      
      if (eventResponse.success && eventResponse.data != null) {
        print('Found upcoming calendar event: ${eventResponse.data!.title}');
        calendarState.setNextEvent(eventResponse.data);
        
        if (eventResponse.data!.location.isNotEmpty) {
          try {
            final coordinates = await _geocodeAddress(eventResponse.data!.location);
            
            if (coordinates != null) {
              print('Geocoded event location: (${coordinates.latitude}, ${coordinates.longitude})');
              calendarState.setEventLocation(coordinates);
              
              await _preloadPlacesAlongRoute(
                context,
                LatLng(position.latitude, position.longitude),
                coordinates,
                allPlaces
              );
            }
          } catch (e) {
            print('Error geocoding event address: $e');
          }
        }
      } else {
        print('No upcoming calendar events found');
      }
      
      print('Updating restaurant provider with ${allPlaces.length} total places');
      restaurantProvider.setPlaces(allPlaces.values.toList());
      
      print('Data preloading complete!');
      
    } catch (e) {
      print('Error during data preloading: $e');
    }
  }
  
  static Future<void> _preloadPlacesAlongRoute(
    BuildContext context, 
    LatLng origin, 
    LatLng destination,
    Map<String, Place> allPlaces
  ) async {
    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      
      print('Preloading places along route from (${origin.latitude}, ${origin.longitude}) '
          'to (${destination.latitude}, ${destination.longitude})');
      
      final nearDestinationResponse = await placeService.getNearbyPlaces(
        lat: destination.latitude,
        lng: destination.longitude,
        radius: 1500,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (nearDestinationResponse.success && nearDestinationResponse.data != null) {
        for (var place in nearDestinationResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${nearDestinationResponse.data!.length} places near destination');
      }
      
      final midLat = (origin.latitude + destination.latitude) / 2;
      final midLng = (origin.longitude + destination.longitude) / 2;
      
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
        origin.latitude, origin.longitude,
        destination.latitude, destination.longitude
      );
      
      if (distance > 3000) {
        final quarterLat = origin.latitude + (destination.latitude - origin.latitude) * 0.25;
        final quarterLng = origin.longitude + (destination.longitude - origin.longitude) * 0.25;
        
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
        
        final threeQuarterLat = origin.latitude + (destination.latitude - origin.latitude) * 0.75;
        final threeQuarterLng = origin.longitude + (destination.longitude - origin.longitude) * 0.75;
        
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
      
      print('📊 Total places along route: ${allPlaces.length}');
      
    } catch (e) {
      print('Error preloading places along route: $e');
    }
  }
  
  static Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final apiKey = MapsConstants.mapsKey;
      if (apiKey.isEmpty) return null;
      
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedAddress'
        '&key=$apiKey'
      );
      
      final client = http.Client();
      final response = await client.get(url);
      
      if (response.statusCode != 200) return null;
      
      final data = json.decode(response.body);
      
      if (data['status'] != 'OK' || data['results'].isEmpty) return null;
      
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
  
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000;
    final phi1 = lat1 * (math.pi / 180);
    final phi2 = lat2 * (math.pi / 180);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180);
    
    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
             math.cos(phi1) * math.cos(phi2) *
             math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return r * c;
  }
}