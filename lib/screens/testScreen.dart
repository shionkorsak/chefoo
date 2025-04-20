import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../services/maps.dart';
import '../models/api_response.dart';
import '../models/restaurant.dart';
import 'package:http/http.dart' as http;

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isLoading = false;
  List<Place> _places = [];

  Future<void> _fetchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final placeService = PlaceService(client: http.Client());

    final lat = 37.7749; // Latitude for San Francisco
    final lng = -122.4194; // Longitude for San Francisco
    final radius = 1000.0; // Radius in meters

    final response = await placeService.getNearbyPlaces(
      lat: lat,
      lng: lng,
      radius: radius,
      apiKey: apiKey,
    );

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _places = response.data!;
      } else {
        _places = [];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Places Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _places.isEmpty
                ? const Center(child: Text("No places found"))
                : ListView.builder(
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(place.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Address: ${place.address}"),
                              Text("Distance: ${place.distance.toStringAsFixed(2)} km"),
                              Text("Phone: ${place.phone ?? 'Not available'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchNearbyPlaces,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
