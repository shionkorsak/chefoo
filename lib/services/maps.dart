import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:chefoo/constants.dart';
import 'package:chefoo/providers/favorites.dart';
import 'package:chefoo/services/popular_times.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

//const String proxyBaseUrl = 'http://localhost:3000';

class PlaceService {
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final http.Client client;

  final Map<String, List<Place>> _cachedPlaces = {};

  Map<String, List<Place>> get cachedPlaces => _cachedPlaces;

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
          return details;
        }
      }
      throw Exception('Failed to load place details');
    } catch (e) {
      print('Error in getPlaceDetails: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getFullPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$baseUrl/details/json'
      '?place_id=$placeId'
      '&fields='
      'place_id,name,geometry,formatted_address,formatted_phone_number,'
      'opening_hours,rating,reviews,types,photos'
      '&key=${MapsConstants.mapsKey}',
    );

    try {
      log('Fetching details for $placeId');
      final response = await client.get(url);

      log('Google API response ${response.statusCode}');
      if(response.statusCode != 200) throw Exception('HTTP error: ${response.statusCode}');;

      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      log('Response JSON: ${jsonEncode(jsonData)}');

      final result = jsonData['result'] as Map<String, dynamic>;

      final geometry = result['geometry'];
      if (geometry == null || geometry['location'] == null) {
        throw Exception('Missing geometry or location for place $placeId');
      }

      if (geometry['location']['lat'] == null || geometry['location']['lng'] == null) {
        throw Exception('Missing lat/lng in geometry for place $placeId');
      }
      
      return result;
    } catch (e) {
      log('Failed to fetch place details for $placeId: $e');
      rethrow;
    }
  }

  Future<void> loadPlaceDetails(Place place) async {
    if (place.detailsLoaded) return;
    
    try {
      final details = await getPlaceDetails(place.id);
      
      if (details['formatted_phone_number'] != null) {
        place.phone = details['formatted_phone_number'];
      }
      
      if (details['opening_hours'] != null && 
          details['opening_hours']['weekday_text'] != null) {
        place.openingHours = List<String>.from(details['opening_hours']['weekday_text']);
      }
      
      if (details['reviews'] != null) {
        final reviews = (details['reviews'] as List).map((r) {
          return Review(
            authorName: r['author_name'] ?? 'Anonymous',
            rating: (r['rating'] ?? 0).toDouble(),
            text: r['text'] ?? '',
            time: r['time']?.toString(),
            photoReference: r['profile_photo_url'],
          );
        }).toList();
        
        place.reviews = reviews;
      }
      
      if (details['photos'] != null) {
        final photos = details['photos'] as List;
        for (var photo in photos) {
          if (photo['photo_reference'] != null && 
              !place.pictureUrls.contains(photo['photo_reference'])) {
            place.pictureUrls.add(photo['photo_reference']);
          }
        }
      }
      
      place.markDetailsLoaded();
    } catch (e) {
      print('Error getting place details: $e');
      throw e;
    }
  }

  Future<ApiResponse<List<Place>>> getNearbyPlaces({
    required double lat,
    required double lng,
    required double radius,
    required String apiKey,
    bool skipCache = false,
    bool addToCache = false,
    bool fetchDetails = false,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}_$radius';
    
    if (!skipCache && _cachedPlaces.containsKey(cacheKey)) {
      print('Using cached places data for key: $cacheKey with ${_cachedPlaces[cacheKey]!.length} places');
      return ApiResponse(
        success: true,
        message: 'Places loaded from cache',
        data: _cachedPlaces[cacheKey],
      );
    }

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
            
            print('Restaurant "${place['name']}" has these types: $types');
            
            if (_isFoodRelatedPlace(types)) {
              print('[MAPS] Testing if place is food related.');
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
                  final details = fetchDetails 
                    ? await getPlaceDetails(place['place_id'])
                    : {'photos': place['photos'], 'types': place['types']};
                  
                  final tags = _convertTypesToTags(types);
                  
                  print('Converted to these tags: $tags');
                  
                  final placeWithDetails = Place.fromGooglePlace(place, details);
                  placeWithDetails.tags = tags;
                  
                  placeWithDetails.walkingDistance = walkingDistance;
                  places.add(placeWithDetails);
                  print('Added food place: ${placeWithDetails.name} (${walkingDistance}km walking)');
                } else {
                  print('[MAPS] Walking distance more than 1.');
                }
              } catch (e) {
                print('Error processing place: $e');
                continue;
              }
            }
          }

          if (addToCache || !_cachedPlaces.containsKey(cacheKey)) {
            _cachedPlaces[cacheKey] = places;
            print('Cached ${places.length} places with key: $cacheKey');
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

  Future<ApiResponse<List<LatLng>>> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      print('Getting directions from (${origin.latitude}, ${origin.longitude}) to (${destination.latitude}, ${destination.longitude})');
      
      final apiKey = MapsConstants.mapsKey;
      print('Using API key: ${apiKey.isEmpty ? "MISSING!" : "Present"}');
      
      if (apiKey.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'API key not found',
          error: 'Missing Google Maps API key',
        );
      }
    
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$apiKey'
      );
      
      print('Directions URL: $url');
      final response = await client.get(url);
      
      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        return ApiResponse(
          success: false,
          message: 'Failed to get directions',
          error: 'API returned ${response.statusCode}',
        );
      }
      
      final data = json.decode(response.body);
      
      print('API Status: ${data['status']}');
      
      if (data['status'] != 'OK') {
        return ApiResponse(
          success: false,
          message: 'Route not found',
          error: data['status'],
        );
      }
      
      final points = _decodePolyline(
        data['routes'][0]['overview_polyline']['points']
      );
      
      print('Decoded ${points.length} route points');
      
      return ApiResponse(
        success: true,
        message: 'Route loaded successfully',
        data: points,
      );
    } catch (e) {
      print('Error in getDirections: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to get directions',
        error: e.toString(),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        
        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        
        double latitude = lat / 1e5;
        double longitude = lng / 1e5;
        
        points.add(LatLng(latitude, longitude));
      }
    } catch (e) {
      print('Error decoding polyline: $e');
    }
    
    return points;
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

  List<String> _convertTypesToTags(List<String> types) {
    final Map<String, String> typeToTag = {
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'bakery': 'Bakery',
      'bar': 'Bar',
      'meal_takeaway': 'Takeout',
      'food': 'Food',
      'meal_delivery': 'Delivery',
      'supermarket': 'Grocery',
      'convenience_store': 'Convenience',
      'grocery_or_supermarket': 'Grocery',
      'fast_food': 'Fast Food',
      'pizza': 'Pizza',
      'burger': 'Burger',
      'sushi': 'Sushi',
      'italian': 'Italian',
    };
    
    final tags = <String>[];
    for (final type in types) {
      if (typeToTag.containsKey(type)) {
        tags.add(typeToTag[type]!);
      }
    }
    
    if (tags.isEmpty) {
      tags.add('NoTag');
    }
    
    return tags;
  }

  Future<bool> fetchPopularTimes(Place place) async {
    if (place.popularTimesLoaded) {
      return place.popularTimes != null;
    }
    
    try {
      final popularTimesService = PopularTimesService();
      final popularTimes = await popularTimesService.getPopularTimes(place.id);
      
      place.setPopularTimes(popularTimes);
      
      return popularTimes != null;
    } catch (e) {
      print('Error fetching popular times: $e');
      place.setPopularTimes(null);
      return false;
    }
  }

  void updateCacheWithRoutePlaces(String cacheKey, List<Place> routePlaces) {
    print('UPDATING CACHE: key=$cacheKey with ${routePlaces.length} route places');
    
    if (!_cachedPlaces.containsKey(cacheKey)) {
      _cachedPlaces[cacheKey] = [];
      print('Created new cache entry for key: $cacheKey');
    }
    
    final List<Place> existingPlaces = _cachedPlaces[cacheKey] ?? [];
    print('Found ${existingPlaces.length} existing places in cache');
    
    final Map<String, Place> mergedPlaces = {};
    
    for (var place in existingPlaces) {
      mergedPlaces[place.id] = place;
    }
    
    for (var place in routePlaces) {
      mergedPlaces[place.id] = place;
    }
    
    _cachedPlaces[cacheKey] = mergedPlaces.values.toList();
    
    print('CACHE UPDATED: Now has ${_cachedPlaces[cacheKey]!.length} places');
    
    final baseLoc = cacheKey.split('_')[0];
    for (var radius in [1000.0, 1500.0, 2000.0, 3000.0]) {
      final alternateKey = '${baseLoc}_${radius}';
      if (alternateKey != cacheKey) {
        if (!_cachedPlaces.containsKey(alternateKey)) {
          _cachedPlaces[alternateKey] = [];
        }
        
        final Map<String, Place> altPlaces = {};
        for (var place in _cachedPlaces[alternateKey]!) {
          altPlaces[place.id] = place;
        }
        
        for (var place in routePlaces) {
          altPlaces[place.id] = place;
        }
        
        _cachedPlaces[alternateKey] = altPlaces.values.toList();
        print('Updated alternate cache key: $alternateKey with ${_cachedPlaces[alternateKey]!.length} places');
      }
    }
  }

  Future<String> exportCachedPlacesToJson(BuildContext context) async {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    final Set<String> processedIds = {};
    final List<Map<String, dynamic>> placesJson = [];
    
    void addPlacesToResult(List<Place> places) {
      for (var place in places) {
        if (processedIds.contains(place.id)) continue;
        
        processedIds.add(place.id);
        
        placesJson.add({
          'id': place.id,
          'name': place.name,
          'rating': place.rating,
          'tags': place.tags,
          'isFavorite': favoritesProvider.isFavorite(place.id),
        });
      }
    }
    
    for (final cacheEntry in _cachedPlaces.entries) {
      addPlacesToResult(cacheEntry.value);
    }
    
    print('Exported ${placesJson.length} unique cached places to JSON');
    
    final jsonString = jsonEncode(placesJson);
    final JsonEncoder prettyEncoder = JsonEncoder.withIndent('  ');
    
    print('\n===== EXPORTED JSON DATA (${placesJson.length} places) =====');
    const int chunkSize = 3; 
    
    for (int i = 0; i < placesJson.length; i += chunkSize) {
      final end = (i + chunkSize < placesJson.length) ? i + chunkSize : placesJson.length;
      final chunk = placesJson.sublist(i, end);
      print(prettyEncoder.convert(chunk));
    }
    
    print('===== END OF JSON DATA =====\n');
    
    return jsonString;
  }
  Future<List<Map<String, dynamic>>> exportCachedPlacesAsList(BuildContext context) async {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    final Set<String> processedIds = {};
    final List<Map<String, dynamic>> placesJson = [];

    void addPlacesToResult(List<Place> places) {
      for (var place in places) {
        if (processedIds.contains(place.id)) continue;

        processedIds.add(place.id);

        placesJson.add({
          'id': place.id,
          'name': place.name,
          'rating': place.rating,
          'tags': place.tags,
          'isFavorite': favoritesProvider.isFavorite(place.id),
        });
      }
    }

    for (final cacheEntry in _cachedPlaces.entries) {
      addPlacesToResult(cacheEntry.value);
    }

    print('Exported ${placesJson.length} unique cached places as List');

    return placesJson;
  }

}
