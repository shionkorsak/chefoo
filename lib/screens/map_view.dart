import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

// [FRONTEND]: GO DIRECTLY TO SECTION 8 AND 9 FOR UI

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
  // SECTION 1: CONSTANTS
  static const double _initialZoom = 20.0;
  static const double _maxZoom = 21.0;
  static const double _minZoom = 16.0;
  static const double _mapPadding = 50.0;
  static const double _boundsPadding = 0.1;

  // SECTION 2: STATE VARIABLES
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Place? _selectedPlace;
  int _selectedIndex = -1;
  Set<Polyline> _polylines = {};
  CalendarEvent? _calendarEvent;
  LatLng? _eventLocation;
  bool _isLoadingRoute = false;
  bool _hasActiveRoute = false;
  bool _showPlaceCard = false;
  bool _isNavigatingToEvent = false;

  Place? get selectedEnrichedPlace {
    if (_selectedPlace == null) return null;

    final recommendedProvider = Provider.of<RecommendedProvider>(context, listen: false);
    final res = recommendedProvider.recommended.firstWhere(
      (p) => p.id == _selectedPlace!.id,
      orElse: () => recommendedProvider.enriched.firstWhere(
        (p) => p.id == _selectedPlace!.id,
        orElse: () => _selectedPlace!,
      ),
    );

    print('${_selectedPlace!.id} ${res.id}');
    return res;
  }


  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // SECTION 3: INITIALIZATION METHODS
  void _initializeMap() {
    _createMarkersWithDestination();

    if (widget.destination != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _drawRouteToDestination(
          widget.destination!,
          widget.destinationName ?? 'Event Location',
        );
      });
    } else {
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
      final start = LatLng(
        locationService.currentPosition!.latitude, 
        locationService.currentPosition!.longitude
      );
      final end = LatLng(
        calendarState.eventLocation!.latitude,
        calendarState.eventLocation!.longitude
      );

      final bounds = _calculateRouteViewBounds(start, end);

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50)
      );

      Future.delayed(Duration(milliseconds: 500), () {
        _mapController!.animateCamera(CameraUpdate.zoomBy(-0.8));
      });
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

  // SECTION 4: EVENT HANDLING METHODS (calendar & routing)
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

            final locationService = Provider.of<LocationService>(context, listen: false);
            final start = locationService.currentPosition;
            if (start != null) {
              final routeKey = '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}-${coordinates.latitude.toStringAsFixed(4)},${coordinates.longitude.toStringAsFixed(4)}';
              await _loadPlacesAlongRouteImplementation(LatLng(start.latitude, start.longitude), coordinates, routeKey);
            }

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

  // SECTION 5: ROUTE & MAP MANIPULATION
  Future<void> _drawRouteToDestination(LatLng destination, String destinationName) async {
    print('Drawing route to $destinationName');

    if (_mapController == null) {
      print('Map controller is null');
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _hasActiveRoute = true;
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

      print('Loading places along route before drawing...');
      await _loadPlacesAlongRoute(destination);
      print('Places along route loaded successfully');

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

  Future<void> _drawRouteToEvent() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final start = locationService.currentPosition;
    final end = widget.destination;

    if (start == null || end == null) return;

    final routeKey =
        '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}-${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}';

    print('⭐️ Drawing route with key: $routeKey');

    setState(() {
      _isLoadingRoute = true;
      _hasActiveRoute = true;
      _polylines.clear();
      print('Cleared existing polylines');
    });

    try {
      print('Loading places along route before drawing...');
      await _loadPlacesAlongRoute(end);  // Ensure this calls the wrapper method
      print('Places along route loaded successfully');

      print('Getting directions from (${start.latitude}, ${start.longitude}) to (${end.latitude}, ${end.longitude})');

      final placeService = Provider.of<PlaceService>(context, listen: false);

      final response = await placeService.getDirections(
        origin: LatLng(start.latitude, start.longitude),
        destination: end,
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

      _addDestinationMarker(end, widget.destinationName ?? 'Event Location');
      _fitRouteAndDestination(start, end);

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
    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    
    if (position == null) return;
    
    final start = LatLng(position.latitude, position.longitude);
    final routeKey = '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}-${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
    
    await _loadPlacesAlongRouteImplementation(start, destination, routeKey);
  }

  Future<void> _loadPlacesAlongRouteImplementation(LatLng start, LatLng end, String routeKey) async {
    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

      print('Loading places along route from (${start.latitude}, ${start.longitude}) to (${end.latitude}, ${end.longitude})');

      final Map<String, Place> allPlaces = {};

      final nearStartResponse = await placeService.getNearbyPlaces(
        lat: start.latitude,
        lng: start.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );

      if (nearStartResponse.success && nearStartResponse.data != null) {
        for (var place in nearStartResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${nearStartResponse.data!.length} places near start location');
      }

      final nearEndResponse = await placeService.getNearbyPlaces(
        lat: end.latitude,
        lng: end.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );

      if (nearEndResponse.success && nearEndResponse.data != null) {
        for (var place in nearEndResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${nearEndResponse.data!.length} places near end location');
      }

      final midpointLat = (start.latitude + end.latitude) / 2;
      final midpointLng = (start.longitude + end.longitude) / 2;

      final midpointResponse = await placeService.getNearbyPlaces(
        lat: midpointLat,
        lng: midpointLng,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
      );

      if (midpointResponse.success && midpointResponse.data != null) {
        for (var place in midpointResponse.data!) {
          allPlaces[place.id] = place;
        }
        print('Loaded ${midpointResponse.data!.length} places at route midpoint');
      }

      final quarterLat = start.latitude + (end.latitude - start.latitude) * 0.25;
      final quarterLng = start.longitude + (end.longitude - start.longitude) * 0.25;

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

      final threeQuarterLat = start.latitude + (end.latitude - start.latitude) * 0.75;
      final threeQuarterLng = start.longitude + (end.longitude - start.longitude) * 0.75;

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

      final places = allPlaces.values.toList();

      restaurantProvider.setRoutePlaces(places, routeKey);

      print('Total unique places along route: ${places.length}');
      print('Places along route loaded successfully');

      if (mounted) {
        setState(() {
          _createMarkersWithDestination();
        });
      }
    } catch (e) {
      print('Error loading places along route: $e');
    }
  }

  // SECTION 6: UTILITY METHODS
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000;
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

    final distanceKm = _calculateDistance(
      position.latitude, position.longitude,
      destination.latitude, destination.longitude
    ) / 1000;
    
    print('DEBUG: Distance between points is $distanceKm km');
    
    final adaptivePadding = distanceKm < 0.2 ? 0.001 :
                          distanceKm < 0.5 ? 0.002 :
                          distanceKm < 2 ? 0.01 : 
                          distanceKm < 5 ? 0.03 : 0.1;
    
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        math.min(position.latitude, destination.latitude) - adaptivePadding,
        math.min(position.longitude, destination.longitude) - adaptivePadding
      ),
      northeast: LatLng(
        math.max(position.latitude, destination.latitude) + adaptivePadding, 
        math.max(position.longitude, destination.longitude) + adaptivePadding
      )
    );

    final edgePadding = distanceKm < 0.8 ? 30.0 : 50.0;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, edgePadding)
    );
    
    Future.delayed(Duration(milliseconds: 500), () {
      if (distanceKm < 0.2) {
        _mapController!.animateCamera(CameraUpdate.zoomBy(1.0));
      } else if (distanceKm < 0.9) {
        _mapController!.animateCamera(CameraUpdate.zoomBy(0.9));
      } else if (distanceKm > 1.0) {
        _mapController!.animateCamera(CameraUpdate.zoomBy(-0.5));
      }
    });
  }

  LatLngBounds _calculateRouteViewBounds(LatLng start, LatLng end) {
    double minLat = math.min(start.latitude, end.latitude);
    double maxLat = math.max(start.latitude, end.latitude);
    double minLng = math.min(start.longitude, end.longitude);
    double maxLng = math.max(start.longitude, end.longitude);
    
    if (_polylines.isNotEmpty && _polylines.first.points.isNotEmpty) {
      final polylinePoints = _polylines.first.points;
      
      for (final point in polylinePoints) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }
    
    final diagonalDistance = math.sqrt(
      math.pow(maxLat - minLat, 2) + math.pow(maxLng - minLng, 2)
    );
    
    final adaptivePadding = math.max(0.005, diagonalDistance * 0.3);
    
    print('DEBUG: Route bounds: $minLat,$minLng to $maxLat,$maxLng with padding $adaptivePadding');
    
    return LatLngBounds(
      southwest: LatLng(minLat - adaptivePadding, minLng - adaptivePadding),
      northeast: LatLng(maxLat + adaptivePadding, maxLng + adaptivePadding),
    );
  }

  List<Place> _sortPlacesByDistance() {
    final places = List<Place>.from(widget.places);
    places.sort((a, b) => a.walkingDistance.compareTo(b.walkingDistance));
    return places;
  }

  // SECTION 7: MARKER & UI STATE MANAGEMENT
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
      _showPlaceCard = true;
      _createMarkersWithDestination();
    });
    _centerOnLocation(place.lat, place.lng);

    // [DATABASE]: you can add a function here so that everytime a 📍 gets
    // clicked on, you save it to the database or smth
    // String placeId = place.id;
    // saveToDatabase(placeId);
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

  void _clearRoutes() {
    setState(() {
      _polylines.clear();
      _hasActiveRoute = false;
    });
  }

  void _clearRouteAndPlaces() {
    _clearRoutes();
    
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    restaurantProvider.clearRoutePlaces();
  }

  void _exitNavigation() {
    _clearRouteAndPlaces();
    Navigator.pop(context);
  }

  void _exportPlacesData() async {
    final placeService = Provider.of<PlaceService>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text("Analyzing recommendations...")),
              ],
            ),
          ),
        );
        final placesList = await placeService.exportCachedPlacesAsList(context);

        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('mainPick');
        final response = await callable.call({'data': placesList});
        final List<dynamic> recommendations = response.data['result'];
        final List<Place> allCachedPlaces = placeService.cachedPlaces.values.expand((list) => list).toList();
        // Create a new map to store only recommended places

        final Map<String, List<Place>> newCache = {};
        
        for(var rec in recommendations) {
            final String recId = rec['id'];
            final List<String> recTags = List<String>.from(rec['tags']);

            Place? match;
            try {
                match = allCachedPlaces.firstWhere((p) => p.id == recId);
            } catch (_) {
                match = null;
            }

            if(match != null) {
                final updatedPlace = match.copyWith(tags: recTags);
                newCache.putIfAbsent('recommended', () => []).add(updatedPlace);
            }
        }

        restaurantProvider.setPlaces(newCache['recommended'] ?? []);
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('Places data exported to console'),
            duration: Duration(seconds: 2),
            ),
        );
    } catch (e) {
        print('Error exporting places data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Error exporting places data: ${e.toString()}'),
            backgroundColor: Colors.red,
            ),
        );
    }
  }

  // SECTION 8: UI COMPONENTS
  Widget _buildRestaurantCard() {
    final enriched = selectedEnrichedPlace;
    if (_selectedPlace == null || enriched == null) {
      return const SizedBox.shrink();
    }

    final pictureUrl = _selectedPlace!.pictureUrls.isNotEmpty 
      ? _selectedPlace!.pictureUrls.first 
      : null;

    final headerImageUrl = selectedEnrichedPlace?.pictureCategory;
      
    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      padding: kPadd10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: kRadius15,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pictureUrl != null)
            Container(
              height: 120,
              width: 120,
              child: ClipRRect(
                borderRadius: kRadius10,
                child: Image.network(
                  headerImageUrl ?? 
                  'https://maps.googleapis.com/maps/api/place/photo'
                  '?maxwidth=400'
                  '&photo_reference=${pictureUrl}'
                  '&key=${MapsConstants.mapsKey}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
            
          SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: Marquee(
                    text: selectedEnrichedPlace!.name,
                    style: AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
                    scrollAxis: Axis.horizontal,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: Duration(seconds: 1),
                    startPadding: 10.0,
                    accelerationDuration: Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  ),
                ),
                  
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: AppColors.primary,
                        ),
                        Text(
                          selectedEnrichedPlace!.rating.toString(),
                          style: AppTextStyles.detail.copyWith(height: 1),
                        )
                      ],
                    ),
                    Text(
                      selectedEnrichedPlace!.tags.isNotEmpty
                          ? selectedEnrichedPlace!.tags.first
                          : 'No tags available',
                      style: AppTextStyles.detail,
                    ),
                  ],
                ),
                
                Text(
                  '${(selectedEnrichedPlace!.walkingDistance * 1000).round()}m',
                  style: AppTextStyles.detail,
                ),
                
                SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (selectedEnrichedPlace!.phone != null)
                      PhoneButton(phoneNumber: selectedEnrichedPlace!.phone ?? '0123456789'),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailScreen(place: selectedEnrichedPlace!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 9: MAIN BUILD METHOD
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
          // SECTION 9.1: MAP
          GoogleMap(
            initialCameraPosition: _getInitialCameraPosition(),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: _onMapCreated,
            onTap: (LatLng position) {
              print("DEBUG: Map tapped at ${position.latitude}, ${position.longitude}");
              
              final wasShowingCard = _showPlaceCard;
              print("DEBUG: wasShowingCard = $wasShowingCard");
              
              setState(() {
                _selectedPlace = null;
                _selectedIndex = -1;
                _showPlaceCard = false;
                _createMarkersWithDestination();
              });

              if (wasShowingCard) {
                if (_hasActiveRoute) {
                  print("DEBUG: Recentering on route");
                  _centerOnRoute();
                } else {
                  final locationService = Provider.of<LocationService>(context, listen: false);
                  final currentPosition = locationService.currentPosition;
                  
                  if (currentPosition != null) {
                    print("DEBUG: Recentering on user location");
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(currentPosition.latitude, currentPosition.longitude),
                        15.0
                      ),
                    );
                  }
                }
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
          
          // SECTION 9.2: RESTAURANT CARD
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _showPlaceCard ? _buildRestaurantCard() : SizedBox.shrink(),
          ),
          
          // SECTION 9.3: LIST VIEW BUTTON
          Positioned(
            right: 16,
            bottom: _selectedPlace != null ? 220 : 16,
            child: FloatingActionButton(
              heroTag: 'listView',
              child: const Icon(Icons.list),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // NEW: EXPORT PLACES DEBUG BUTTON
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'exportData',
              backgroundColor: Colors.green,
              mini: true,
              child: const Icon(Icons.download),
              onPressed: () => _exportPlacesData(),
              tooltip: 'Export Places Data',
            ),
          ),
        ],
      ),
    );
  }
}

// helper class for calculating map bounds <3 dont touch? or do
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