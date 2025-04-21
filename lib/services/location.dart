import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService with ChangeNotifier {
  static const bool debugMode = true; // Set to false for production
  static const debugLat = 24.795653; 
  static const debugLng = 120.991744;

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;
  bool _isRequestingPermission = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LocationService() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      await _checkLocationPermissions();
      await startLocationUpdates();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _checkLocationPermissions() async {
    if (_isRequestingPermission) {
      print('Location permission request already in progress');
      return;
    }

    try {
      _isRequestingPermission = true;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are required.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable in settings.');
      }
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> startLocationUpdates() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
    }

    try {
      if (debugMode) {
        // Use debug location
        _currentPosition = Position(
          latitude: debugLat,
          longitude: debugLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        notifyListeners();
        return;
      }

      // First get a single position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      notifyListeners();

      // Then start listening to position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 3),
        ),
      ).listen(
        (Position position) {
          print('New location: ${position.latitude}, ${position.longitude}');
          _currentPosition = position;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          print('Location stream error: $e');
          _error = e.toString();
          notifyListeners();
        },
      );

    } catch (e) {
      print('Error starting location updates: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _checkLocationPermissions();
      await startLocationUpdates();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentLocation() async {
    if (_isLoading) {
      print('Location update already in progress');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _checkLocationPermissions();
      await startLocationUpdates();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  String getDistanceString(double lat, double lng) {
    if (_currentPosition == null) return '';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
}