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
  final LatLng? destination;
  final String? destinationName;

  const MapViewScreen({
    Key? key,
    required this.places,
    this.destination,
    this.destinationName,
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const double _initialZoom = 20.0;
  static const double _maxZoom = 21.0;
  static const double _minZoom = 17.0;
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
  bool _hasActiveRoute = false;

  @override
  void initState() {
    super.initState();

    _createMarkersWithDestination();

    if (widget.destination != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _drawRouteToDestination(
          widget.destination!,
          widget.destinationName ?? 'Event Location',
        );
      });
    }
    else {
      final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
      if (calendarState.eventLocation != null) {
        _calendarEvent = calendarState.nextEvent;
        _eventLocation = calendarState.eventLocation;

        Future.delayed(const Duration(milliseconds: 300), () {
          _drawRouteToDestination(
            _eventLocation!,
            _calendarEvent?.title ?? 'Event Location',
          );
        });
      }
    }
  }

  CameraPosition _getInitialCameraPosition() {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);

    if (calendarState.nextEvent != null &&
        calendarState.eventLocation != null &&
        locationService.currentPosition != null) {
      _hasActiveRoute = true;

      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(locationService.currentPosition!.latitude, calendarState.eventLocation!.latitude),
          math.min(locationService.currentPosition!.longitude, calendarState.eventLocation!.longitude),
        ),
        northeast: LatLng(
          math.max(locationService.currentPosition!.latitude, calendarState.eventLocation!.latitude),
          math.max(locationService.currentPosition!.longitude, calendarState.eventLocation!.longitude),
        ),
      );

      return CameraPosition(
        target: LatLng(
          (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
          (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
        ),
        zoom: 14.0,
      );
    }

    return CameraPosition(
      target: LatLng(
        locationService.currentPosition?.latitude ?? 0.0,
        locationService.currentPosition?.longitude ?? 0.0,
      ),
      zoom: 15.0,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _centerOnRoute() {
    if (!_hasActiveRoute || _mapController == null) return;

    final locationService = Provider.of<LocationService>(context, listen: false);
    final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);

    if (calendarState.eventLocation != null && locationService.currentPosition != null) {
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(locationService.currentPosition!.latitude, calendarState.eventLocation!.latitude),
          math.min(locationService.currentPosition!.longitude, calendarState.eventLocation!.longitude),
        ),
        northeast: LatLng(
          math.max(locationService.currentPosition!.latitude, calendarState.eventLocation!.latitude),
          math.max(locationService.currentPosition!.longitude, calendarState.eventLocation!.longitude),
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  @override
  void didUpdateWidget(MapViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hasActiveRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnRoute();
      });
    }
    
    if (oldWidget.places != widget.places && _hasActiveRoute) {
      _createMarkersWithDestination();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnRoute();
      });
    }
  }

  Future<void> _fetchNextEvent() async {
    try {
      setState(() {
        _isLoadingRoute = true;
      });

      final calendarService = CalendarService();
      final response = await calendarService.getNextEvent();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _calendarEvent = response.data;
        });

        if (_calendarEvent != null && _calendarEvent!.location.isNotEmpty) {
          final coordinates = await _geocodeAddress(_calendarEvent!.location);

          if (!mounted) return;

          if (coordinates != null) {
            setState(() {
              _eventLocation = coordinates;
            });

            await _loadPlacesAlongRoute(coordinates);

            _drawRouteToDestination(coordinates, _calendarEvent!.title);

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
      final coordinates = await _geocodeAddress(event.location);

      if (!mounted) return;

      if (coordinates != null) {
        setState(() {
          _eventLocation = coordinates;
        });

        _drawRouteToDestination(
          coordinates,
          event.title,
        );

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
      print('Map controller is null');
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _polylines.clear();
      print('Cleared existing polylines');
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;

      if (position == null) {
        print('Current location not available');
        throw Exception('Current location not available');
      }

      print('Getting directions from (${position.latitude}, ${position.longitude}) to (${destination.latitude}, ${destination.longitude})');

      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getDirections(
        origin: LatLng(position.latitude, position.longitude),
        destination: destination,
      );

      if (!response.success || response.data == null || response.data!.isEmpty) {
        print('Failed to get directions: ${response.error}');
        throw Exception("Couldn't get directions: ${response.error ?? 'Unknown error'}");
      }

      print('Got route with ${response.data!.length} points');

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('event_route'),
            color: Colors.blue,
            width: 5,
            points: response.data!,
          ),
        );
        print('Added polyline with ${response.data!.length} points');
        print('Total polylines now: ${_polylines.length}');
      });

      _addDestinationMarker(destination, destinationName);

      _fitRouteAndDestination(position, destination);

    } catch (e) {
      print('ERROR drawing route: $e');
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

      print('Loading places along route from (${position.latitude}, ${position.longitude}) to (${destination.latitude}, ${destination.longitude})');

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
        print('Loaded ${nearCurrentResponse.data!.length} places near current location');
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
        print('Loaded ${nearDestinationResponse.data!.length} places near destination');
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
        print('Loaded ${midpointResponse.data!.length} places near route midpoint');
      }

      final distance = _calculateDistance(
        position.latitude, position.longitude,
        destination.latitude, destination.longitude
      );

      if (distance > 3000) {
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
          print('Loaded ${quarterResponse.data!.length} places at quarter point');
        }

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
          print('Loaded ${threeQuarterResponse.data!.length} places at three-quarter point');
        }
      }

      print('Total unique places along route: ${allPlaces.length}');

      if (mounted) {
        final places = allPlaces.values.toList();
        restaurantProvider.setPlaces(places);

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

    return r * c;
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
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    final sortedPlaces = List<Place>.from(places)
      ..sort((a, b) => a.walkingDistance.compareTo(b.walkingDistance));
      
    print('Creating ${sortedPlaces.length} place markers');
      
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
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    setState(() {
      _selectedPlace = place;
      _selectedIndex = places.indexOf(place);
      _createMarkersWithDestination();
    });
    _centerOnLocation(place.lat, place.lng);
  }

  void _updateSelectedPlace(int index) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    if (index < 0 || index >= places.length) return;
    
    setState(() {
      _selectedIndex = index;
      _selectedPlace = places[index];
      _createMarkersWithDestination();
    });
    _centerOnLocation(_selectedPlace!.lat, _selectedPlace!.lng);
  }

  void _showNextPlace() {
    if (_selectedPlace == null) return;

    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    if (places.isEmpty) return;

    final nextIndex = (_selectedIndex + 1) % places.length;
    _updateSelectedPlace(nextIndex);
  }

  void _showPreviousPlace() {
    if (_selectedPlace == null) return;

    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    if (places.isEmpty) return;

    final previousIndex = (_selectedIndex - 1 + places.length) % places.length;
    _updateSelectedPlace(previousIndex);
  }

  void _fitBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _MapBounds();

    for (final marker in _markers) {
      bounds.extend(marker.position);
    }

    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    if (position != null) {
      bounds.extend(LatLng(position.latitude, position.longitude));
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds.toBounds(), _mapPadding),
    );
  }

  void _centerOnLocation(double lat, double lng) {
    if (_mapController == null) return;
    
    final latLng = LatLng(lat, lng);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, _initialZoom),
    );
  }

  void _resetMapView(Position? currentPosition) {
    if (_mapController == null || currentPosition == null) return;
    
    setState(() {
      _selectedPlace = null;
      _selectedIndex = -1;
      _createMarkersWithDestination();
    });
    
    if (_hasActiveRoute) {
      _centerOnRoute();
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          _initialZoom,
        ),
      );
    }
  }

  Widget _buildRestaurantCard() {
    if (_selectedPlace == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPlace!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OpenStatusBadge(isOpen: _selectedPlace!.isOpenNow ?? false),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              _selectedPlace!.address,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                RestaurantRating(rating: _selectedPlace!.rating),
                const SizedBox(width: 16),
                RestaurantDistance(distanceKm: _selectedPlace!.walkingDistance),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_selectedPlace!.phone != null)
                  PhoneButton(phoneNumber: _selectedPlace!.phone!),
                DirectionsButton(lat: _selectedPlace!.lat, lng: _selectedPlace!.lng),
              ],
            ),
          ],
        ),
      ),
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
            initialCameraPosition: _getInitialCameraPosition(),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: _onMapCreated,
            onTap: (LatLng position) {
              setState(() {
                _selectedPlace = null;
                _selectedIndex = -1;
                _createMarkersWithDestination();
              });
              
              if (_hasActiveRoute) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _centerOnRoute();
                });
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
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