import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location.dart';
import '../models/restaurant.dart';
import '../widgets/base_layout.dart';
import '../widgets/restaurant_card.dart';

class MapViewScreen extends StatefulWidget {
  final List<Place> places;

  const MapViewScreen({
    Key? key,
    required this.places,
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const double _initialZoom = 15.0;
  static const double _maxZoom = 17.0;
  static const double _mapPadding = 50.0;
  static const double _boundsPadding = 0.001;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Place? _selectedPlace;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _sortPlacesByDistance();
    _createMarkers();
  }

  List<Place> _sortPlacesByDistance() {
    final places = List<Place>.from(widget.places);
    places.sort((a, b) => a.walkingDistance.compareTo(b.walkingDistance));
    return places;
  }

  void _createMarkers() {
    final sortedPlaces = _sortPlacesByDistance();
    _markers = sortedPlaces.map((place) {
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
  }

  void _onMarkerTapped(Place place) {
    setState(() {
      _selectedPlace = place;
      _selectedIndex = widget.places.indexOf(place);
      _createMarkers();
    });
    _centerOnLocation(place.lat, place.lng);
  }

  void _updateSelectedPlace(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedPlace = widget.places[index];
      _createMarkers();
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
    for (final marker in _markers) {
      bounds.extend(marker.position);
    }

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

    return BaseLayout(
      title: 'Restaurant Map',
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentPosition.latitude, currentPosition.longitude),
              zoom: _initialZoom,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
            onTap: (_) => _resetMapView(currentPosition),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(_initialZoom, _maxZoom),
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

  _MapBounds extend(LatLng position) {
    minLat = math.min(minLat, position.latitude);
    maxLat = math.max(maxLat, position.latitude);
    minLng = math.min(minLng, position.longitude);
    maxLng = math.max(maxLng, position.longitude);
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