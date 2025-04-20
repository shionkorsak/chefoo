import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../services/maps.dart';
import '../models/api_response.dart';
import '../models/restaurant.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
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
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: 37.7749,
        lng: -122.4194,
        radius: 1000.0,
        apiKey: apiKey,
      );

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _places = response.data!;
          print('Loaded ${_places.length} places');
          for (var place in _places) {
            print('Place loaded: ${place.name}');
          }
        }
      });
    } catch (e) {
      print('Error fetching places: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyPlaces,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? const Center(child: Text('No restaurants found nearby'))
              : ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                Text(' ${place.rating.toStringAsFixed(1)}'),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Address
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(place.address)),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Phone
                                if (place.phone != null) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16),
                                      const SizedBox(width: 8),
                                      Text(place.phone!),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Opening Hours
                                if (place.openingHours != null &&
                                    place.openingHours!.isNotEmpty) ...[
                                  const Text(
                                    'Opening Hours',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ...place.openingHours!.map(
                                    (hours) => Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(hours),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Reviews
                                if (place.reviews.isNotEmpty) ...[
                                  const Text(
                                    'Reviews',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ...place.reviews.map(
                                    (review) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, bottom: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                review.authorName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.star,
                                                  size: 14,
                                                  color: Colors.amber[700]),
                                              Text(
                                                  review.rating.toStringAsFixed(1)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(review.text),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Navigation Button
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final url =
                                          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(place.address)}';
                                      if (await canLaunch(url)) {
                                        await launch(url);
                                      }
                                    },
                                    icon: const Icon(Icons.directions),
                                    label: const Text('Navigate'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
