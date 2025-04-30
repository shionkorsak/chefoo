import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_skeleton/constants.dart';
import 'package:flutter_skeleton/services/popular_times.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//const String proxyBaseUrl = 'http://localhost:3000';

class PlaceService {
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final http.Client client;

  PlaceService({required this.client});

  Future<double> getDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originLat,$originLng'
      '&destinations=$destLat,$destLng'
      '&key=$apiKey',
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'OK') {
        final distanceInMeters = jsonData['rows'][0]['elements'][0]['distance']['value'];
        return distanceInMeters / 1000.0;
      } else {
        throw Exception('Failed to calculate distance');
      }
    } else {
      throw Exception('Failed to load distance data');
    }
  }

  Future<double> getWalkingDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originLat,$originLng'
      '&destinations=$destLat,$destLng'
      '&mode=walking' 
      '&key=$apiKey'
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'OK' && 
          jsonData['rows'][0]['elements'][0]['status'] == 'OK') {
        final distanceInMeters = jsonData['rows'][0]['elements'][0]['distance']['value'];
        return distanceInMeters / 1000.0; 
      }
    }
    throw Exception('Failed to calculate walking distance');
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$baseUrl/details/json'
      '?place_id=$placeId'
      '&fields=formatted_phone_number,opening_hours,reviews,photos,price_level,formatted_address'
      '&key=${MapsConstants.mapsKey}',
    );

    try {
      final response = await client.get(url);
      print('Place details response for $placeId: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK') {
          final details = jsonData['result'];
          
          final popularTimesService = PopularTimesService();
          try {
            final popularTimes = await popularTimesService.getPopularTimes(placeId);
            if (popularTimes != null) {
              details['populartimes'] = popularTimes;
              print('Added popular times data for $placeId');
            }
          } catch (e) {
            print('Error fetching popular times: $e');
          }
          
          return details;
        }
      }
      throw Exception('Failed to load place details');
    } catch (e) {
      print('Error in getPlaceDetails: $e');
      throw e;
    }
  }

  Future<ApiResponse<List<Place>>> getNearbyPlaces({
    required double lat,
    required double lng,
    required double radius,
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/nearbysearch/json'
        '?location=$lat,$lng'
        '&rankby=distance'
        '&type=restaurant|cafe|bakery|meal_takeaway'
        '&key=$apiKey'
      );

      print('Making request to: $url');
      
      final response = await client.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'OK') {
          final results = jsonData['results'] as List;
          print('Found ${results.length} places, limiting to ${AppConfig.MAX_PLACES_TO_LOAD}');
          
          final limitedResults = results.take(AppConfig.MAX_PLACES_TO_LOAD).toList();
          
          final places = <Place>[];

          for (var place in limitedResults) {
            final types = List<String>.from(place['types'] ?? []);
            if (_isFoodRelatedPlace(types)) {
              try {
                final walkingDistance = await getWalkingDistance(
                  originLat: lat,
                  originLng: lng,
                  destLat: place['geometry']['location']['lat'],
                  destLng: place['geometry']['location']['lng'],
                  apiKey: apiKey,
                );

                if (walkingDistance <= 1.0) {
                  print('Fetching details for food place: ${place['name']}');
                  final details = await getPlaceDetails(place['place_id']);
                  final placeWithDetails = Place.fromGooglePlace(place, details);
                  placeWithDetails.walkingDistance = walkingDistance;
                  places.add(placeWithDetails);
                  print('Added food place: ${placeWithDetails.name} (${walkingDistance}km walking)');
                }
              } catch (e) {
                print('Error processing place: $e');
                continue;
              }
            }
          }

          return ApiResponse(
            success: true,
            message: 'Places loaded successfully',
            data: places,
          );
        } else {
          throw Exception('Failed to load places');
        }
      } else {
        throw Exception('Failed to load places');
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return ApiResponse(
        success: false,
        message: 'Network error. Check your internet connection.',
        error: e.toString(),
      );
    } catch (e) {
      print('Error fetching places: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to load places',
        error: e.toString(),
      );
    }
  }

  bool _isFoodRelatedPlace(List<String> types) {
    final foodRelatedTypes = {
      'restaurant',
      'food',
      'cafe',
      'bakery',
      'meal_takeaway',
      'meal_delivery',
      'bar',
      'supermarket',
      'grocery_or_supermarket',
    };

    return types.any((type) => foodRelatedTypes.contains(type));
  }
}
