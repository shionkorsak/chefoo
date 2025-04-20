import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/restaurant.dart';

const String proxyBaseUrl = 'http://localhost:3000'; 

class PlaceService {
  final http.Client client;

  PlaceService({required this.client});

  // Get Distance using the Google Maps Distance Matrix API
  Future<double> getDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      '$proxyBaseUrl/distancematrix'
      '?origins=$originLat,$originLng'
      '&destinations=$destLat,$destLng'
      '&key=$apiKey'  // Pass API key through proxy
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

  // Get phone number using the Google Maps Place Details API
  Future<String?> getPhoneNumber(String placeId, String apiKey) async {
    final url = Uri.parse(
      '$proxyBaseUrl/details'
      '?place_id=$placeId'
      '&key=$apiKey'  // Pass API key through proxy
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final result = jsonData['result'];
      return result['formatted_phone_number'] as String?;
    } else {
      throw Exception('Failed to load place details');
    }
  }

  // Main method to get Nearby Places
  Future<ApiResponse<List<Place>>> getNearbyPlaces({
    required double lat,
    required double lng,
    required double radius,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      '$proxyBaseUrl/nearbysearch'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=restaurant'
      '&key=$apiKey'  // Pass API key through proxy
    );

    try {
      print('Making request to: $url');  // Log the request URL
      final response = await client.get(url);
      
      // Log the response body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Response JSON Data: $jsonData');  // Log the response body in JSON format
        final results = jsonData['results'] as List;

        final places = results.map((item) {
          return Place(
            id: item['place_id'],
            name: item['name'],
            rating: (item['rating'] ?? 0).toDouble(),
            address: item['vicinity'] ?? '',
            distance: 0,
            tags: [],
            phone: null,
            pictureUrls: (item['photos'] as List?)
                    ?.map((p) =>
                        'https://maps.googleapis.com/maps/api/place/photo'
                        '?maxwidth=400'
                        '&photoreference=${p['photo_reference']}'
                        '&key=$apiKey')
                    .toList() ??
                [],
            reviews: [],
          );
        }).toList();

        return ApiResponse(
          success: true,
          message: 'Places loaded',
          data: places,
        );
      } else {
        print('Failed to load places. Status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        return ApiResponse(
          success: false,
          message: 'Failed to load places',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Error occurred: $e');  
      return ApiResponse(
        success: false,
        message: 'Exception occurred',
        error: e.toString(),
      );
    }
  }
}
