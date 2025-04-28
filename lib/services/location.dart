import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService with ChangeNotifier {
  static const bool debugMode = true;  // Set to true for emulator testing
  static const debugLat = 24.795653;   // delta building coordinates
  static const debugLng = 120.991744;

  Position? _currentPosition;
  Position? _lastFetchPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isRequestingPermission = false;
  bool _useDebugLocation = false; 

  Position? get currentPosition => _currentPosition;
  Position? get lastFetchPosition => _lastFetchPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useDebugLocation => _useDebugLocation;

  LocationService() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      await _checkLocationPermissions();
      await getCurrentLocation();
    } catch (e) {
      _error = e.toString();
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

  // New method to toggle between debug and real GPS
  void toggleDebugMode(bool enabled) {
    _useDebugLocation = enabled;
    getCurrentLocation();  // Refresh location with new mode
  }

  Future<void> getCurrentLocation() async {
    if (_isLoading) {
      print('Location update already in progress');
      return;
    }

    // Set loading without notification
    _isLoading = true;

    try {
      if (_useDebugLocation) {
        print('Using debug location: $debugLat, $debugLng');
        _setDebugLocation();
        _lastFetchPosition = _currentPosition;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check location service first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Then check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDebugLocation(); // Fallback to debug location
          _lastFetchPosition = _currentPosition;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDebugLocation(); // Fallback to debug location
        _lastFetchPosition = _currentPosition;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Getting GPS location...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      
      _lastFetchPosition = _currentPosition;
      print('Got GPS location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      _error = null;

    } catch (e) {
      print('Error getting location: $e');
      _error = e.toString();
      _setDebugLocation();
      _lastFetchPosition = _currentPosition;
    } finally {
      _isLoading = false;
      // Single notification at the end
      notifyListeners();
    }
  }

  void _setDebugLocation() {
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
    _error = null;
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _checkLocationPermissions();
      await getCurrentLocation();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLastFetchPosition(Position position) {
    _lastFetchPosition = position;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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