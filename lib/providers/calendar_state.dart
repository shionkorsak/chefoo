import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chefoo/services/calendar_service.dart';

class CalendarStateProvider with ChangeNotifier {
  CalendarEvent? _nextEvent;
  LatLng? _eventLocation;
  bool _hasLoadedRoute = false;
  List<LatLng>? _routePolyline;
  
  CalendarEvent? get nextEvent => _nextEvent;
  LatLng? get eventLocation => _eventLocation;
  bool get hasLoadedRoute => _hasLoadedRoute;
  List<LatLng>? get routePolyline => _routePolyline;
  
  void setNextEvent(CalendarEvent? event) {
    _nextEvent = event;
    notifyListeners();
  }
  
  void setEventLocation(LatLng? location) {
    _eventLocation = location;
    notifyListeners();
  }
  
  void setHasLoadedRoute(bool value) {
    _hasLoadedRoute = value;
    notifyListeners();
  }
  
  void setRoutePolyline(List<LatLng>? polylinePoints) {
    _routePolyline = polylinePoints;
    notifyListeners();
  }
  
  void clearEventData() {
    _nextEvent = null;
    _eventLocation = null;
    _hasLoadedRoute = false;
    notifyListeners();
  }
}