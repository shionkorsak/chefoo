import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String proxyBaseUrl = 'http://localhost:3000';

class PlaceService {
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
      '$proxyBaseUrl/distancematrix'
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

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$proxyBaseUrl/details?place_id=$placeId',
    );

    print('Requesting place details for place_id: $placeId');

    try {
      final response = await client.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK') {
          return jsonData['result'];
        } else {
          print('API Error: ${jsonData['error_message']}');
          throw Exception(jsonData['error_message']);
        }
      } else {
        throw Exception('Failed to load place details');
      }
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
    final url = Uri.parse(
      '$proxyBaseUrl/nearbysearch'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=restaurant'
      '&key=$apiKey',
    );

    try {
      print('Making request to: $url');
      final response = await client.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final results = jsonData['results'] as List;
        final places = <Place>[];

        for (var place in results) {
          try {
            final details = await getPlaceDetails(place['place_id']);
            final placeWithDetails = Place.fromGooglePlace(place, details);
            places.add(placeWithDetails);
            print('Added place: ${placeWithDetails.name}');
          } catch (e) {
            print('Error processing place: $e');
            continue;
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
    } catch (e) {
      print('Error fetching places: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to load places',
        error: e.toString(),
      );
    }
  }
}

class NearbyPlacesScreen extends StatefulWidget {
  @override
  _NearbyPlacesScreenState createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  bool _isLoading = false;
  List<Place> _places = [];

  Future<void> _fetchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final placeService = PlaceService(client: http.Client());

    final lat = 37.7749;
    final lng = -122.4194;
    final radius = 1000.0;

    try {
      final response = await placeService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radius: radius,
        apiKey: apiKey,
      );

      print('Nearby places response: ${response.message}');

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _places = response.data!;
          print('Loaded places: ${_places.length}');
          for (var place in _places) {
            print('Place: ${place.name}, Reviews: ${place.reviews.length}');
          }
        } else {
          _places = [];
          print('No places found');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching nearby places: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI for ${_places.length} places');
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Places'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? const Center(child: Text("No places found. Please try again."))
              : ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            Text("Rating: ${place.rating.toStringAsFixed(1)}"),

                            Text("Address: ${place.address}"),

                            Text("Phone: ${place.phone ?? 'Not available'}"),

                            if (place.openingHours?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              const Text("Opening Hours:", style: TextStyle(fontWeight: FontWeight.bold)),
                              ...?place.openingHours?.map((h) => Text(h)).toList(),
                            ],

                            if (place.reviews.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              const Text("Reviews:", style: TextStyle(fontWeight: FontWeight.bold)),
                              ...place.reviews.map((review) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.authorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text("Rating: ${review.rating.toStringAsFixed(1)}"),
                                      Text(review.text),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchNearbyPlaces,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
