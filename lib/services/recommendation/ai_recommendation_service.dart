import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RecommendationService  {
  final PlaceService placeService;
  final RestaurantProvider restaurantProvider;
  final FirebaseFunctions functions;

  RecommendationService ({
    required this.placeService,
    required this.restaurantProvider,
    FirebaseFunctions? firebaseFunctions,
  }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

  Future<List<Place>> fetchAndRecommendNearbyPlaces(Position position, BuildContext context) async {
    final cacheKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_1000';
    print('Fetching places for location: ${position.latitude}, ${position.longitude}');
    print('Using cache key: $cacheKey for nearby places');

    try {
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey
      );

      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');

        final placesList = await placeService.exportCachedPlacesAsList(context);

        final HttpsCallable callable = functions.httpsCallable('mainPick');
        final aiResponse = await callable.call({'data': placesList});
        final List<dynamic> recommendations = aiResponse.data['result'];
        if(recommendations.isEmpty) {
          log('AI returned no recommendations. Falling back to raw places.');
          
        }
        final allCachedPlaces = placeService.cachedPlaces.values
          .expand((list) => list)
          .fold<Map<String, Place>>({}, (map, place) {
            map[place.id] = place;
            return map;
          })
          .values
          .toList();

        print('all cached: ${allCachedPlaces.length}');
        final List<Place> recommendedPlaces = [];

        for (var rec in recommendations) {
          final String recId = rec['id'];
          final List<String> recTags = List<String>.from(rec['tags']);
          final String recCat = rec['pictureCategory'];

          Place? match = allCachedPlaces.where((p) => p.id == recId).firstOrNull;

          if (match != null) {
            final updatedPlace = match.copyWith(
              tags: recTags, 
              pictureCategory: recCat
            );
            recommendedPlaces.add(updatedPlace);
          }
        }

        final Set<String> recommendedIds = recommendedPlaces.map((p) => p.id).toSet();
        print('[AI] Recommended IDs: $recommendedIds');

        final List<Place> filteredPlaces = allCachedPlaces.where((p) => !recommendedIds.contains(p.id)).toList();
        final List<Place> filteredOut = allCachedPlaces.where((p) => recommendedIds.contains(p.id)).toList();

        print('[AI] Filtered out (recommended):');
        for (final p in filteredOut) {
          print(' - ${p.name} (ID: ${p.id})');
        }

        final List<Place> enrichedFilteredPlaces = [];
        print('[AI] Generating banner and tags:');
        for (final place in filteredPlaces) {
          try {
            final response = await functions.httpsCallable('generateTagsAndBanner').call({'name': place.name});
            final List<String> tags = List<String>.from(response.data['tags']);
            final String banner = response.data['pictureCategory'];

            final enriched = place.copyWith(
              tags: tags,
              pictureCategory: banner,
            );

            enrichedFilteredPlaces.add(enriched);
            print('- ${enriched.name}; Tags: ${enriched.tags}; Banner: ${enriched.pictureCategory}');
          } catch (e) {
            print('Failed to enrich "${place.name}": $e');
            enrichedFilteredPlaces.add(place);
          }
        }
        restaurantProvider.setPlaces(enrichedFilteredPlaces);
        
        final printPlaces = restaurantProvider.places;

        for (final place in printPlaces) {
          print('${place.name} - Tags: ${place.tags.join(", ")} | Banner: ${place.pictureCategory}');
        }

        log('Returning ${recommendedPlaces.length} recommended places to controller.');

        return recommendedPlaces;
      } else {
        print('Failed to load places: ${response.message}');
        return [];
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      rethrow; 
    }
  }

  Future<void> fetchWithMessage(String userMessage, BuildContext context, Position position) async {
    final cacheKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_1000';
    print('Fetching places for location: ${position.latitude}, ${position.longitude}');
    print('Using cache key: $cacheKey for nearby places');

    try {
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey,
      );

      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');

        final placesList = await placeService.exportCachedPlacesAsList(context);

        final HttpsCallable callable = functions.httpsCallable('msgAI');
        final aiResponse = await callable.call({
          'message': userMessage,
          'restaurants': placesList,
        });

        final List<dynamic> recommendations = aiResponse.data;
        if (recommendations.isEmpty) {
          log('AI returned no recommendations. Falling back to raw places.');
        }

        final List<Place> allCachedPlaces = placeService.cachedPlaces.values.expand((list) => list).toList();
        final Map<String, List<Place>> newCache = {};

        for (var rec in recommendations) {
          final String recId = rec['id'];
          final List<String> recTags = List<String>.from(rec['tags']);
          final String recCat = rec['pictureCategory'];

          Place? match = allCachedPlaces.where((p) => p.id == recId).firstOrNull;

          if (match != null) {
            final updatedPlace = match.copyWith(
              tags: recTags,
              pictureCategory: recCat,
            );
            newCache.putIfAbsent('recommended', () => []).add(updatedPlace);
          }
        }

        restaurantProvider.setPlaces(newCache['recommended'] ?? []);

        if (response.message.contains('cache') == true) {
          print('Used cache with ${response.data!.length} places');
        }
      } else {
        print('Failed to load places: ${response.message}');
      }
    } catch (e) {
      print('Error fetching nearby places with message: $e');
      rethrow;
    }
  }

  Future<void> generateTagsAndBannerForPlace(String restaurantName, Function(String tag, String banner)? onResult) async {
    try {
      final HttpsCallable callable = functions.httpsCallable('generateTagsAndBanner');
      final response = await callable.call({'name': restaurantName});

      final data = response.data;
      final List<String> tags = List<String>.from(data['tags']);
      final String pictureCategory = data['pictureCategory'];

      print('Tags for $restaurantName: $tags');
      print('Picture category: $pictureCategory');

      if (onResult != null) {
        for (final tag in tags) {
          onResult(tag, pictureCategory);
        }
      }
    } catch (e) {
      print('Failed to generate tags and banner for "$restaurantName": $e');
      rethrow;
    }
  }
}
