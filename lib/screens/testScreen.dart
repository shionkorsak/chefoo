import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location.dart';
import '../services/maps.dart';
import '../models/restaurant.dart';

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
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();
    await _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;

      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getNearbyPlaces(
        lat: position!.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: apiKey,
      );

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _places = response.data!;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showAllPictures(BuildContext context, List<String> pictures, String placeName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('All photos - $placeName'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: pictures.length,
                itemBuilder: (context, index) => Image.network(
                  '$proxyBaseUrl/photo'
                  '?maxwidth=800'
                  '&photo_reference=${pictures[index]}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDistanceString(double lat, double lng) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final currentPosition = locationService.currentPosition;
    if (currentPosition == null) return '';

    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      lat,
      lng,
    );

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nearby Restaurants'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await locationService.getCurrentLocation();
                  await _fetchNearbyPlaces();
                },
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
                                    const SizedBox(width: 16),
                                    if (locationService.currentPosition != null) ...[
                                      Icon(Icons.location_on, size: 16),
                                      Text(' ${_getDistanceString(place.lat, place.lng)}'),
                                      const SizedBox(width: 16),
                                    ],
                                    if (place.isOpenNow != null) ...[
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: place.isOpenNow! ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        place.isOpenNow! ? 'Open' : 'Closed',
                                        style: TextStyle(
                                          color: place.isOpenNow! ? Colors.green : Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
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
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(place.address)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (place.pictureUrls.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Photos',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        height: 100,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: place.pictureUrls.length > 3
                                                    ? 3
                                                    : place.pictureUrls.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        '$proxyBaseUrl/photo'
                                                        '?maxwidth=400'
                                                        '&photo_reference=${place.pictureUrls[index]}',
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Container(
                                                            width: 100,
                                                            height: 100,
                                                            color: Colors.grey[200],
                                                            child: const Center(
                                                              child: CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            width: 100,
                                                            height: 100,
                                                            color: Colors.grey[200],
                                                            child: const Icon(Icons.error),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            if (place.pictureUrls.length > 3)
                                              InkWell(
                                                onTap: () => _showAllPictures(
                                                  context,
                                                  place.pictureUrls,
                                                  place.name,
                                                ),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '+${place.pictureUrls.length - 3}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                    if (place.reviews.isNotEmpty) ...[
                                      const Text(
                                        'Reviews',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      ...place.reviews.map(
                                        (review) => Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                            bottom: 16.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          review.authorName,
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                                            Text(review.rating.toStringAsFixed(1)),
                                                            const SizedBox(width: 8),
                                                            if (review.time != null)
                                                              Text(
                                                                _formatTimestamp(int.parse(review.time!)),
                                                                style: TextStyle(
                                                                  color: Colors.grey[600],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(review.text),
                                              if (review.photoReference != null) ...[
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    '$proxyBaseUrl/photo'
                                                    '?maxwidth=400'
                                                    '&photo_reference=${review.photoReference}',
                                                    height: 150,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 150,
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 150,
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.error),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              const Divider(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
      },
    );
  }
}
