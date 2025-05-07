import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:chefoo/services/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';
import '../services/location.dart';
import '../widgets/base_layout.dart';
import '../widgets/restaurant_card.dart';

class MapViewScreen extends StatefulWidget {
  final List<Place> places;
  final LatLng? destination; // Add this parameter
  final String? destinationName; // Add this parameter

  const MapViewScreen({
    Key? key,
    required this.places,
    this.destination, // Add this parameter
    this.destinationName, // Add this parameter
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const double _initialZoom = 18.0;
  static const double _maxZoom = 20.0; // Initial + 2 levels
  static const double _minZoom = 16.0; // Initial - 2 levels
  static const double _mapPadding = 50.0;
  static const double _boundsPadding = 0.001;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Place? _selectedPlace;
  int _selectedIndex = -1;
  Set<Polyline> _polylines = {};
  CalendarEvent? _calendarEvent;
  LatLng? _eventLocation;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    
    // If we have a specific destination from the widget
    if (widget.destination != null) {
      // Load places along this specific route
      Future.delayed(Duration.zero, () {
        _loadPlacesAlongRoute(widget.destination!);
        
        // Draw the route after a small delay to ensure the map is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          _drawRouteToDestination(
            widget.destination!,
            widget.destinationName ?? 'Event Location',
          );
        });
      });
    } 
    // Otherwise fetch calendar data and use that
    else {
      _fetchNextEvent(); // This will handle loading places and drawing the route
    }
  }

  Future<void> _fetchNextEvent() async {
    try {
      setState(() {
        _isLoadingRoute = true;
      });
      
      // Get calendar service
      final calendarService = CalendarService();
      final response = await calendarService.getNextEvent();
      
      if (!mounted) return;
      
      if (response.success && response.data != null) {
        // Store the event
        setState(() {
          _calendarEvent = response.data;
        });
        
        // If we have an event with location, geocode it
        if (_calendarEvent != null && _calendarEvent!.location.isNotEmpty) {
          // Geocode the address to get coordinates
          final coordinates = await _geocodeAddress(_calendarEvent!.location);
          
          if (!mounted) return;
          
          if (coordinates != null) {
            // Store the event location
            setState(() {
              _eventLocation = coordinates;
            });
            
            // Load places along the route
            await _loadPlacesAlongRoute(coordinates);
            
            // Draw the route
            _drawRouteToDestination(coordinates, _calendarEvent!.title);
            
            // Store in provider for other screens to use
            if (mounted) {
              final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
              calendarState.setNextEvent(_calendarEvent);
              calendarState.setEventLocation(coordinates);
            }
          }
        }
      } else {
        print('No upcoming events found');
      }
    } catch (e) {
      print('Error fetching next event: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Future<void> _geocodeAndDrawRoute(CalendarEvent event) async {
    try {
      // Geocode the address
      final coordinates = await _geocodeAddress(event.location);
      
      if (!mounted) return;
      
      if (coordinates != null) {
        // Store the location
        setState(() {
          _eventLocation = coordinates;
        });
        
        // Draw the route
        _drawRouteToDestination(
          coordinates,
          event.title,
        );
        
        // Store in provider for other screens to use
        final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
        calendarState.setNextEvent(event);
        calendarState.setEventLocation(coordinates);
      }
    } catch (e) {
      print('Error geocoding event address: $e');
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
      
      final client = http.Client();
      final response = await client.get(url);
      
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

  Future<void> _drawRouteToDestination(LatLng destination, String destinationName) async {
    print('⭐️ Drawing route to $destinationName');
    
    if (_mapController == null) {
      print('❌ Map controller is null');
      return;
    }
    
    setState(() {
      _isLoadingRoute = true;
      // Clear existing polylines first
      _polylines.clear();
      print('🔄 Cleared existing polylines');
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;

      if (position == null) {
        print('❌ Current location not available');
        throw Exception('Current location not available');
      }

      print('📍 Getting directions from (${position.latitude}, ${position.longitude}) to (${destination.latitude}, ${destination.longitude})');
      
      final placeService = Provider.of<PlaceService>(context, listen: false);
      
      // Get directions
      final response = await placeService.getDirections(
        origin: LatLng(position.latitude, position.longitude),
        destination: destination,
      );
      
      if (!response.success || response.data == null || response.data!.isEmpty) {
        print('❌ Failed to get directions: ${response.error}');
        throw Exception("Couldn't get directions: ${response.error ?? 'Unknown error'}");
      }
      
      print('✅ Got route with ${response.data!.length} points');

      // Draw the route
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('event_route'),
            color: Colors.blue,
            width: 5,
            points: response.data!,
          ),
        );
        print('🔵 Added polyline with ${response.data!.length} points');
        print('🔄 Total polylines now: ${_polylines.length}');
      });

      // Make sure we have a destination marker
      _addDestinationMarker(destination, destinationName);
      
      // Fit the map to show the entire route
      _fitRouteAndDestination(position, destination);
      
    } catch (e) {
      print('❌ ERROR drawing route: $e');
      // Don't show error to user unless it's a critical failure
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Future<void> _loadPlacesAlongRoute(LatLng destination) async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;
      
      if (position == null) {
        print('Current location not available');
        return;
      }
      
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      
      print('📍 Loading places along route from (${position.latitude}, ${position.longitude}) to (${destination.latitude}, ${destination.longitude})');
      
      // Create a combined Map to avoid duplicate places
      final Map<String, Place> allPlaces = {};
      
      // 1. Load places near current location
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
        print('📍 Loaded ${nearCurrentResponse.data!.length} places near current location');
      }
      
      // 2. Load places near destination
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
        print('📍 Loaded ${nearDestinationResponse.data!.length} places near destination');
      }
      
      // 3. Load places near midpoint of the route
      final midLat = (position.latitude + destination.latitude) / 2;
      final midLng = (position.longitude + destination.longitude) / 2;
      
      final midpointResponse = await placeService.getNearbyPlaces(
        lat: midLat,
        lng: midLng,
        radius: 1500, // Slightly larger radius for midpoint
        apiKey: MapsConstants.mapsKey,
      );
      
      if (midpointResponse.success && midpointResponse.data != null) {
        for (var place in midpointResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('📍 Loaded ${midpointResponse.data!.length} places near route midpoint');
      }
      
      // 4. If the distance is significant, add a quarter and three-quarter points
      final distance = _calculateDistance(
        position.latitude, position.longitude,
        destination.latitude, destination.longitude
      );
      
      if (distance > 3000) { // If more than 3km apart
        // Quarter point
        final quarterLat = position.latitude + (destination.latitude - position.latitude) * 0.25;
        final quarterLng = position.longitude + (destination.longitude - position.longitude) * 0.25;
        
        final quarterResponse = await placeService.getNearbyPlaces(
          lat: quarterLat,
          lng: quarterLng,
          radius: 1000,
          apiKey: MapsConstants.mapsKey,
        );
        
        if (quarterResponse.success && quarterResponse.data != null) {
          for (var place in quarterResponse.data!) {
            allPlaces[place.id] = place;
          }
          print('📍 Loaded ${quarterResponse.data!.length} places at quarter point');
        }
        
        // Three-quarter point
        final threeQuarterLat = position.latitude + (destination.latitude - position.latitude) * 0.75;
        final threeQuarterLng = position.longitude + (destination.longitude - position.longitude) * 0.75;
        
        final threeQuarterResponse = await placeService.getNearbyPlaces(
          lat: threeQuarterLat,
          lng: threeQuarterLng,
          radius: 1000,
          apiKey: MapsConstants.mapsKey,
        );
        
        if (threeQuarterResponse.success && threeQuarterResponse.data != null) {
          for (var place in threeQuarterResponse.data!) {
            allPlaces[place.id] = place;
          }
          print('📍 Loaded ${threeQuarterResponse.data!.length} places at three-quarter point');
        }
      }
      
      print('📍 Total unique places along route: ${allPlaces.length}');
      
      // Update the places in the provider
      if (mounted) {
        final places = allPlaces.values.toList();
        restaurantProvider.setPlaces(places);
        
        // Update our local UI with these places
        setState(() {
          _createMarkersWithDestination();
        });
      }
    } catch (e) {
      print('Error loading places along route: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000; // Earth radius in meters
    final phi1 = lat1 * (math.pi / 180);
    final phi2 = lat2 * (math.pi / 180);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180);
    
    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
             math.cos(phi1) * math.cos(phi2) *
             math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return r * c; // Distance in meters
  }

  void _addDestinationMarker(LatLng destination, String name) {
    final marker = Marker(
      markerId: const MarkerId('event_destination'),
      position: destination,
      infoWindow: InfoWindow(
        title: name,
        snippet: 'Your calendar event',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      zIndex: 10,
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _fitRouteAndDestination(Position position, LatLng destination) {
    if (_mapController == null) return;

    final south = math.min(position.latitude, destination.latitude);
    final north = math.max(position.latitude, destination.latitude);
    final west = math.min(position.longitude, destination.longitude);
    final east = math.max(position.longitude, destination.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(south - 0.01, west - 0.01),
      northeast: LatLng(north + 0.01, east + 0.01),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  List<Place> _sortPlacesByDistance() {
    final places = List<Place>.from(widget.places);
    places.sort((a, b) => a.walkingDistance.compareTo(b.walkingDistance));
    return places;
  }

  void _createMarkersWithDestination() {
    final sortedPlaces = _sortPlacesByDistance();
    final Set<Marker> markers = sortedPlaces.map((place) {
      final isSelected = place.id == _selectedPlace?.id;

      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        zIndex: isSelected ? 2 : 1,
        onTap: () => _onMarkerTapped(place),
      );
    }).toSet();

    // Add destination marker from widget.destination (direct navigation)
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('event_destination'),
          position: widget.destination!,
          infoWindow: InfoWindow(
            title: widget.destinationName ?? 'Event Location',
            snippet: 'Your event location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndex: 10,
        ),
      );
    }
    // Also check for destination from calendar provider
    else if (_eventLocation != null && _calendarEvent != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('event_destination'),
          position: _eventLocation!,
          infoWindow: InfoWindow(
            title: _calendarEvent!.title,
            snippet: _calendarEvent!.location,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndex: 10,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(Place place) {
    setState(() {
      _selectedPlace = place;
      _selectedIndex = widget.places.indexOf(place);
      _createMarkersWithDestination();
    });
    _centerOnLocation(place.lat, place.lng);
  }

  void _updateSelectedPlace(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedPlace = widget.places[index];
      _createMarkersWithDestination();
    });
    _centerOnLocation(_selectedPlace!.lat, _selectedPlace!.lng);
  }

  void _centerOnLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  void _resetMapView(Position position) {
    setState(() {
      _selectedPlace = null;
      _selectedIndex = -1;
    });
    _centerOnLocation(position.latitude, position.longitude);
  }

  Widget _buildNavigationArrows() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavigationButton(
            icon: Icons.arrow_back_ios,
            onPressed: _showPreviousPlace,
          ),
          const SizedBox(width: 32),
          _buildNavigationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _showNextPlace,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        disabledBackgroundColor: Colors.black12,
      ),
    );
  }

  Widget _buildRestaurantCard() {
    if (_selectedPlace == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavigationArrows(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: RestaurantCard(place: _selectedPlace!),
        ),
      ],
    );
  }

  void _showNextPlace() {
    if (_selectedPlace == null || widget.places.isEmpty) return;

    final nextIndex = (_selectedIndex + 1) % widget.places.length;
    _updateSelectedPlace(nextIndex);
  }

  void _showPreviousPlace() {
    if (_selectedPlace == null || widget.places.isEmpty) return;

    final previousIndex = (_selectedIndex - 1 + widget.places.length) % widget.places.length;
    _updateSelectedPlace(previousIndex);
  }

  void _fitBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _MapBounds();

    // Add all place markers to bounds
    for (final marker in _markers) {
      bounds.extend(marker.position);
    }

    // Add current location to bounds
    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    if (position != null) {
      bounds.extend(LatLng(position.latitude, position.longitude));
    }

    // Add padding to create some margin
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds.toBounds(), _mapPadding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final currentPosition = locationService.currentPosition;

    if (currentPosition == null) {
      return const BaseLayout(
        title: 'Restaurant Map',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Choose the most relevant title based on available destination info
    String pageTitle = 'Restaurant Map';
    if (widget.destinationName != null) {
      pageTitle = 'Route to ${widget.destinationName}';
    } else if (_calendarEvent?.title != null) {
      pageTitle = 'Route to ${_calendarEvent!.title}';
    }

    return BaseLayout(
      title: pageTitle,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentPosition.latitude, currentPosition.longitude),
              zoom: _initialZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              print('Map created');
              _mapController = controller;

              // Fit bounds based on what information we have
              if (widget.destination != null) {
                // If we have destination from widget props
                final locationService = Provider.of<LocationService>(context, listen: false);
                final position = locationService.currentPosition;
                if (position != null) {
                  _fitRouteAndDestination(position, widget.destination!);
                }
              } else if (_eventLocation != null) {
                // If we already fetched the event location
                final locationService = Provider.of<LocationService>(context, listen: false);
                final position = locationService.currentPosition;
                if (position != null) {
                  _fitRouteAndDestination(position, _eventLocation!);
                }
              } else {
                // Otherwise just fit to current places
                _fitBounds();
              }
            },
            onTap: (_) => _resetMapView(currentPosition),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            // Disable all gestures except zoom
            scrollGesturesEnabled: false, // Prevent moving the map
            zoomGesturesEnabled: true, // Allow pinch-to-zoom
            rotateGesturesEnabled: false, // Prevent rotation
            tiltGesturesEnabled: false, // Prevent tilt
            compassEnabled: false, // Hide compass since rotation is disabled
            // Apply zoom restrictions
            minMaxZoomPreference: MinMaxZoomPreference(_minZoom, _maxZoom),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildRestaurantCard(),
          ),
          Positioned(
            right: 16,
            bottom: _selectedPlace != null ? 220 : 16,
            child: FloatingActionButton(
              heroTag: 'listView',
              child: const Icon(Icons.list),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBounds {
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;

  _MapBounds extend(LatLng point) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
    return this;
  }

  LatLngBounds toBounds() {
    return LatLngBounds(
      southwest: LatLng(minLat - _MapViewScreenState._boundsPadding, 
                       minLng - _MapViewScreenState._boundsPadding),
      northeast: LatLng(maxLat + _MapViewScreenState._boundsPadding, 
                       maxLng + _MapViewScreenState._boundsPadding),
    );
  }
}