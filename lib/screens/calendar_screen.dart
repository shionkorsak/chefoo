import 'dart:convert';

import 'package:chefoo/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chefoo/commons.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/screens/testScreen.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';

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

  Future<void> _fetchNextEvent({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);
      final response = await calendarService.getNextEvent(forceRefresh: forceRefresh);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _nextEvent = response.data;
          _isLoading = false;
        });
      } else {
        if (response.message == 'User not signed in' ||
            response.message == 'Google Sign-in required for calendar') {
          final shouldRefresh = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Calendar Access Needed'),
              content: Text('We need permission to access your calendar. Would you like to grant access now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Grant Access'),
                ),
              ],
            ),
          ) ?? false;

          if (shouldRefresh && mounted) {
            await Provider.of<AuthService>(context, listen: false).googleSignIn.signOut();
            await Provider.of<AuthService>(context, listen: false).googleSignIn.signIn();
            _fetchNextEvent();
            return;
          }
        }

        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error loading calendar: $e';
      });
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
              _fetchNextEvent(forceRefresh: true);
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
              onPressed: () => _fetchNextEvent(forceRefresh: true),
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

      await _geocodeAddressAndFindRestaurants(context, event.location);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TestScreen()),
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

  Future<void> _geocodeAddressAndFindRestaurants(BuildContext context, String address) async {
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
        throw Exception('Failed to geocode address: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) {
        throw Exception('No location found for address: $address');
      }

      final location = data['results'][0]['geometry']['location'];
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;

      print('Geocoded "$address" to: $lat, $lng');

      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final placeService = Provider.of<PlaceService>(context, listen: false);

      restaurantProvider.setLoading(true);

      final restaurantResponse = await placeService.getNearbyPlaces(
        lat: lat,
        lng: lng,
        radius: 1000.0,
        apiKey: apiKey,
      );

      if (!restaurantResponse.success) {
        throw Exception(restaurantResponse.message);
      }

      restaurantProvider.setPlaces(restaurantResponse.data!);

    } catch (e) {
      print('Error in geocoding: $e');
      rethrow;
    } finally {
      if (context.mounted) {
        Provider.of<RestaurantProvider>(context, listen: false).setLoading(false);
      }
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