import 'dart:convert';
import 'dart:math';
import 'package:chefoo/main.dart';
import 'package:chefoo/screens/map_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:chefoo/providers/calendar_state.dart' as provider;
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/calendar_state.dart' as provider;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarEvent? _nextEvent;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNextEvent();
  }

  Future<void> _fetchNextEvent() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final calendarService = CalendarService();
      final response = await calendarService.getNextEvent();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _nextEvent = response.data;
          _isLoading = false;
        });

        if (_nextEvent != null) {
          final providerInstance = Provider.of<provider.CalendarStateProvider>(context, listen: false);
          providerInstance.setNextEvent(_nextEvent);

          if (_nextEvent!.location.isNotEmpty) {
            _geocodeAndStoreEventLocation(_nextEvent!.location);
          }
        }
      } else {
        setState(() {
          _error = response.error ?? 'Unknown error';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodeAndStoreEventLocation(String address) async {
    try {
      final coordinates = await _geocodeAddress(address);

      if (coordinates != null && mounted) {
        final providerInstance = Provider.of<provider.CalendarStateProvider>(context, listen: false);
        providerInstance.setEventLocation(coordinates);
      }
    } catch (e) {
      print('Error geocoding event address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchNextEvent();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing calendar events...'))
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCalendarContent(),
      ),
    );
  }

  Widget _buildCalendarContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNextEvent,
              child: const Text('Try Again'),
            )
          ],
        ),
      );
    }

    if (_nextEvent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No upcoming events with locations found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchNextEvent(),
              child: const Text('Refresh Calendar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showAllEvents,
              child: const Text('Debug: Show All Calendar Events'),
            )
          ],
        ),
      );
    }

    final localStartTime = _nextEvent!.startTime.toLocal();

    final formattedTime = '${localStartTime.hour.toString().padLeft(2, '0')}:${localStartTime.minute.toString().padLeft(2, '0')}';

    final formattedDate = _getReadableDate(localStartTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nextEvent!.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_nextEvent!.location)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text('$formattedDate at $formattedTime'),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'View this event on your map by going to the Map tab',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _showAllEvents,
          child: const Text('Debug: Show All Calendar Events'),
        )
      ],
    );
  }

  Future<void> _findRestaurantsNearEvent(BuildContext context, CalendarEvent event) async {
    try {
      setState(() => _isLoading = true);
      
      LatLng? destination = await _geocodeAddress(event.location);
      
      if (!mounted) return;
      
      if (destination == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find location on map')),
        );
        return;
      }

      final response = await _loadPlacesAlongRoute(destination);
      
      if (!response.success || response.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurants: ${response.message}')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapViewScreen(
            places: response.data!,
            destination: destination,
            destinationName: event.title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<ApiResponse<List<Place>>> _loadPlacesAlongRoute(LatLng destination) async {
    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      final position = locationService.currentPosition;
      if (position == null) {
        return ApiResponse(
          success: false,
          message: 'Location not available',
          error: 'Cannot access current location',
        );
      }
      
      final Map<String, Place> allPlaces = {};
      
      final nearCurrentResponse = await placeService.getNearbyPlaces(
        lat: position.latitude, 
        lng: position.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );
      
      if (nearCurrentResponse.success && nearCurrentResponse.data != null) {
        for (var place in nearCurrentResponse.data!) {
          allPlaces[place.id] = place;
        }
      }
      
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
      }
      
      return ApiResponse(
        success: true,
        message: 'Places loaded successfully',
        data: allPlaces.values.toList(),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error loading places: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
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
      
      final response = await http.get(url);
      
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

  String _getReadableDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _showAllEvents() async {
    setState(() => _isLoading = true);

    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);
      
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in with Firebase'))
        );
        return;
      }
      
      final authService = Provider.of<AuthService>(context, listen: false);
      GoogleSignInAccount? account = authService.googleSignIn.currentUser;
      
      if (account == null) {
        account = await authService.googleSignIn.signInSilently();
        if (account == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not signed in with Google - try refreshing the page'))
          );
          return;
        }
      }

      final auth = await account.authentication;
      final now = DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();

      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?maxResults=50'
        '&orderBy=startTime'
        '&singleEvents=true'
        '&timeMin=$now'
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final events = data['items'] as List;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('All Calendar Events (${events.length})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['summary'] ?? 'No title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (event['location'] != null)
                          Text('Location: ${event['location']}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              )),
                        Text(
                          'Start: ${event['start']['dateTime'] ?? event['start']['date']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}