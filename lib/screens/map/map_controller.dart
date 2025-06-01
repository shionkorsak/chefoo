import 'dart:math' as math;
import 'dart:convert';
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:chefoo/screens/map/map_screen.dart';

abstract class MapController extends State<MapScreen> {
  // SECTION 1: CONSTANTS (converted to instance variables)
  final double initialZoom = 18.0;
  final double maxZoom = 18.0;
  final double minZoom = 16.0;
  final double mapPadding = 50.0;
  final double boundsPadding = 0.1;

  // SECTION 2: STATE VARIABLES (removed underscores)
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Place? selectedPlace;
  int selectedIndex = -1;
  Set<Polyline> polylines = {};
  CalendarEvent? calendarEvent;
  LatLng? eventLocation;
  bool isLoadingRoute = false;
  bool hasActiveRoute = false;
  bool showPlaceCard = false;
  bool isNavigatingToEvent = false;
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  @override
  void initState() {
    super.initState();
  }

  // Basic map setup functions
  CameraPosition getInitialCameraPosition() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);

    if (calendarState.nextEvent != null &&
        calendarState.eventLocation != null &&
        locationService.currentPosition != null) {
      hasActiveRoute = true;

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

  void onMapCreated(GoogleMapController controller) {
    print("Map controller created");
    mapController = controller;
  }

  void centerOnRoute() {
    if (!hasActiveRoute || mapController == null) return;

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

      final bounds = calculateRouteViewBounds(start, end);

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50)
      );

      Future.delayed(Duration(milliseconds: 500), () {
        mapController!.animateCamera(CameraUpdate.zoomBy(-0.8));
      });
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (hasActiveRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        centerOnRoute();
      });
    }
    
    if (oldWidget.places != widget.places && hasActiveRoute) {
      createMarkersWithDestination();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        centerOnRoute();
      });
    }
  }

  // SECTION 4: GEOCODING (simplified)
  Future<LatLng?> geocodeAddress(String address) async {
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

  // SECTION 5: ROUTE FUNCTIONS
  Future<void> drawRouteToDestination(LatLng destination, String destinationName) async {
    print('STARTING ROUTE DRAWING to $destinationName');
    print('Destination: ${destination.latitude}, ${destination.longitude}');

    if (mapController == null) {
      print('Map controller is null');
      return;
    }

    try {
      setState(() {
        isLoadingRoute = true;
        hasActiveRoute = true;
        polylines.clear();
        print('Cleared existing polylines');
      });

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

      print('Direction API response: success=${response.success}, error=${response.error}, points=${response.data?.length ?? 0}');

      if (!response.success || response.data == null || response.data!.isEmpty) {
        print('Failed to get directions: ${response.error}');
        throw Exception("Couldn't get directions: ${response.error ?? 'Unknown error'}");
      }

      print('Got route with ${response.data!.length} points');

      final newPolyline = Polyline(
        polylineId: const PolylineId('event_route'),
        color: Colors.blue,
        width: 4,
        points: response.data!,
        visible: true,
      );
      
      setState(() {
        polylines.add(newPolyline);
        print('Added polyline: ${polylines.length} in set, visible=${newPolyline.visible}, width=${newPolyline.width}');
      });

      print('Adding destination marker');
      addDestinationMarker(destination, destinationName);
      
      print('Fitting bounds to route');
      fitRouteAndDestination(position, destination);
      
      print('ROUTE DRAWING COMPLETE');
    } catch (e) {
      print('Error drawing route: $e');
    } finally {
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  Future<void> loadPlacesAlongRoute(LatLng destination) async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    
    if (position == null) return;
    
    final start = LatLng(position.latitude, position.longitude);
    final routeKey = '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}-${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
    
    await loadPlacesAlongRouteImplementation(start, destination, routeKey);
  }

  Future<void> loadPlacesAlongRouteImplementation(LatLng start, LatLng end, String routeKey) async {
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
      
      if (mounted) {
        setState(() {
          createMarkersWithDestination();
        });
      }
    } catch (e) {
      print('Error loading places along route: $e');
    }
  }

  // SECTION 6: UTILITY METHODS
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  void addDestinationMarker(LatLng destination, String name) {
    print('Adding destination marker at ${destination.latitude}, ${destination.longitude}');
    
    final marker = Marker(
      markerId: const MarkerId('event_destination'),
      position: destination,
      infoWindow: InfoWindow(
        title: name,
        snippet: 'Your calendar event',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      zIndex: 10,
      visible: true,
    );

    markers.removeWhere((m) => m.markerId.value == 'event_destination');
    
    setState(() {
      markers.add(marker);
      print('Destination marker added, total markers: ${markers.length}');
    });
  }

  void fitRouteAndDestination(Position position, LatLng destination) {
    if (mapController == null) {
      print("Cannot fit bounds: Map controller is null");
      return;
    }
    
    print("Fitting bounds for route");
    
    final double distanceKm = calculateDistance(
      position.latitude, position.longitude,
      destination.latitude, destination.longitude
    ) / 1000;
    
    print("Route distance: ${distanceKm.toStringAsFixed(3)} km");
    
    final padding = distanceKm < 0.5 ? 100.0 : 50.0;
    
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        math.min(position.latitude, destination.latitude) - 0.001,
        math.min(position.longitude, destination.longitude) - 0.001
      ),
      northeast: LatLng(
        math.max(position.latitude, destination.latitude) + 0.001, 
        math.max(position.longitude, destination.longitude) + 0.001
      )
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding)
    );
  }

  LatLngBounds calculateRouteViewBounds(LatLng start, LatLng end) {
    double minLat = math.min(start.latitude, end.latitude);
    double maxLat = math.max(start.latitude, end.latitude);
    double minLng = math.min(start.longitude, end.longitude);
    double maxLng = math.max(start.longitude, end.longitude);
    
    if (polylines.isNotEmpty && polylines.first.points.isNotEmpty) {
      final polylinePoints = polylines.first.points;
      
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
    
    return LatLngBounds(
      southwest: LatLng(minLat - adaptivePadding, minLng - adaptivePadding),
      northeast: LatLng(maxLat + adaptivePadding, maxLng + adaptivePadding),
    );
  }

  // SECTION 7: MARKER & UI STATE MANAGEMENT
  void createMarkersWithDestination() {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    final placesToShow = places.length > 50 ? places.sublist(0, 50) : places;
        
    final Set<Marker> newMarkers = {};

    for (var place in placesToShow) {
      final isSelected = place.id == selectedPlace?.id;
      
      final marker = Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        zIndex: isSelected ? 2 : 1,
        onTap: () => onMarkerTapped(place),
      );
      
      newMarkers.add(marker);
    }

    if (widget.destination != null) {
      newMarkers.add(
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
    
    // Update the markers
    if (mounted) {
      setState(() {
        markers = newMarkers;
      });
    }
  }

  void onMarkerTapped(Place place) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    setState(() {
      selectedPlace = place;
      selectedIndex = places.indexOf(place);
      showPlaceCard = true;
      createMarkersWithDestination();
    });
    centerOnLocation(place.lat, place.lng);
  }

  void updateSelectedPlace(int index) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final places = restaurantProvider.places.isNotEmpty 
        ? restaurantProvider.places 
        : widget.places;
        
    if (index < 0 || index >= places.length) return;
    
    setState(() {
      selectedIndex = index;
      selectedPlace = places[index];
      createMarkersWithDestination();
    });
    
    centerOnLocation(selectedPlace!.lat, selectedPlace!.lng);
  }

  void fitBounds() {
    if (mapController == null || markers.isEmpty) return;

    final bounds = MapBounds();
    
    for (final marker in markers) {
      bounds.extend(marker.position);
    }

    final locationService = Provider.of<LocationService>(context, listen: false);
    final position = locationService.currentPosition;
    if (position != null) {
      bounds.extend(LatLng(position.latitude, position.longitude));
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds.toBounds(), mapPadding),
    );
  }

  void centerOnLocation(double lat, double lng) {
    if (mapController == null) return;
    
    final latLng = LatLng(lat, lng);
    mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, initialZoom),
    );
  }

  void forceDrawRoute() {
    print("Attempting to force draw route...");
    final locationService = Provider.of<LocationService>(context, listen: false);
    final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
    
    if (locationService.currentPosition == null) {
      print("Cannot draw route: Current location unavailable");
      return;
    }
    
    // Case 1: Use destination from widget parameters
    if (widget.destination != null) {
      print("Drawing route to explicit destination: ${widget.destinationName}");
      drawRouteToDestination(
        widget.destination!,
        widget.destinationName ?? 'Destination',
      );
    }
    // Case 2: Use calendar event destination
    else if (calendarState.eventLocation != null) {
      print("Drawing route to calendar event: ${calendarState.nextEvent?.title}");
      eventLocation = calendarState.eventLocation;
      calendarEvent = calendarState.nextEvent;
      
      drawRouteToDestination(
        eventLocation!,
        calendarEvent?.title ?? 'Event Location',
      );
    }
    else {
      print("No destination available for route drawing");
    }
  }
}

// Helper class for map bounds calculation
class MapBounds {
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;

  MapBounds extend(LatLng point) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
    return this;
  }

  LatLngBounds toBounds() {
    return LatLngBounds(
      southwest: LatLng(minLat - 0.1, minLng - 0.1),
      northeast: LatLng(maxLat + 0.1, maxLng + 0.1),
    );
  }
}