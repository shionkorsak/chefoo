import 'package:chefoo/providers/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:chefoo/services/maps.dart';

class LocationService with ChangeNotifier {
  static const bool debugMode = true; 
  static const debugLat = 24.795653;   // delta building coordinates
  static const debugLng = 120.991744;

  Position? _currentPosition;
  Position? _lastFetchPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isRequestingPermission = false;
  bool _useDebugLocation = false; 

  bool _locationChangedSignificantly = false;

  final _locationChangedController = StreamController<Position>.broadcast();
  Stream<Position> get locationChangedStream => _locationChangedController.stream;

  Position? get currentPosition => _currentPosition;
  Position? get lastFetchPosition => _lastFetchPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useDebugLocation => _useDebugLocation;
  bool get locationChangedSignificantly => _locationChangedSignificantly;

  DateTime _lastLocationUpdate = DateTime.now();

  bool _isFirstLocationUpdate = true;
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

  void toggleDebugMode(bool enabled) {
    _useDebugLocation = enabled;
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    if (_isLoading) {
      print('Location update already in progress');
      return;
    }

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

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDebugLocation();
          _lastFetchPosition = _currentPosition;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDebugLocation();
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
    _locationChangedController.close();
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

  Stream<Position> get locationStream => Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, //needed to change for demo
        ),
      );

  void startLocationUpdates(BuildContext context) {
    print('[LOC SVC] Starting location updates');
    
    _positionStreamSubscription?.cancel();
    
    _positionStreamSubscription = locationStream.listen((position) {
      _currentPosition = position;
      
      print('[LOC SVC] Location update received: ${position.latitude}, ${position.longitude}');
      
      if (_isFirstLocationUpdate) {
        print('[LOC SVC] First location update received, storing as reference');
        _lastFetchPosition = position;
        _isFirstLocationUpdate = false;
        notifyListeners();
        return;
      }
      
      if (_lastFetchPosition == null) {
        _lastFetchPosition = position;
        return;
      }
      
      final distance = calculateGeoDistance(
        _lastFetchPosition!.latitude,
        _lastFetchPosition!.longitude,
        position.latitude,
        position.longitude
      );
      
      print('[LOC SVC] Movement detected: ${distance.toStringAsFixed(2)}m');
      
      if (distance > 100) {
        print('[LOC SVC] Location changed significantly (${distance.toStringAsFixed(2)}m)');
        _locationChangedSignificantly = true;
        
        _lastFetchPosition = position;
        
        _locationChangedController.add(position);
        
        notifyListeners();
      }
    });
  }

  void resetLocationChangedFlag() {
    _locationChangedSignificantly = false;
  }

  double calculateDistance(Position pos1, Position pos2) {
    return calculateGeoDistance(
      pos1.latitude, 
      pos1.longitude, 
      pos2.latitude, 
      pos2.longitude
    );
  }

  bool isChangedVerySignificantly(Position newPosition) {
    if (_lastFetchPosition == null) {
      print('[LOC SVC] Cannot determine if change is significant: no previous position');
      return false;
    }
    
    final distance = calculateGeoDistance(
      _lastFetchPosition!.latitude,
      _lastFetchPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude
    );
    
    final isSignificant = distance > 1000;
    
    print('[LOC SVC] Distance moved: ${distance.toStringAsFixed(2)}m, Is very significant: $isSignificant');
    
    return isSignificant;
  }
}