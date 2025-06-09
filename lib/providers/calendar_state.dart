import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarStateProvider with ChangeNotifier {
  final CalendarService _calendarService = CalendarService();
  bool _calendarEnabled = false;
  String? _selectedCalendarId;
  CalendarEvent? _nextEvent;
  LatLng? _eventLocation;
  bool _hasLoadedRoute = false;

  bool get calendarEnabled => _calendarEnabled;
  String? get selectedCalendarId => _selectedCalendarId;
  CalendarEvent? get nextEvent => _nextEvent;
  LatLng? get eventLocation => _eventLocation;
  bool get hasLoadedRoute => _hasLoadedRoute;

  void setCalendarEnabled(bool enabled) {
    _calendarEnabled = enabled;
    notifyListeners();
  }

  void setSelectedCalendarId(String id) {
    _selectedCalendarId = id;
    notifyListeners();
  }

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

  void clearEventData() {
    _nextEvent = null;
    _eventLocation = null;
    _hasLoadedRoute = false;
    notifyListeners();
  }


  Future<bool> checkCalendarPermissions() async {
    try {
      var status = await Permission.calendar.status;
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          print('Calendar permission permanently denied. User needs to enable it in settings.');
        }
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final hasCalendarId = prefs.getString('selected_calendar_id') != null;
      
      _calendarEnabled = status.isGranted && hasCalendarId;
      _selectedCalendarId = prefs.getString('selected_calendar_id');
      
      return _calendarEnabled;
    } catch (e) {
      print('Error checking calendar permissions: $e');
      return false;
    }
  }

  Future<bool> requestCalendarPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('calendar_permission_revoked');
      await prefs.remove('calendar_access_revoked');
      
      final wasRevoked = prefs.getBool('calendar_was_previously_revoked') ?? false;
      
      if (wasRevoked) {
        final authService = AuthService();
        final success = await authService.signInWithGoogleAndCalendarScope();
        if (!success) {
          print('Failed to re-authenticate with calendar scope');
          return false;
        }
      }
      
      final status = await Permission.calendar.request();
      if (!status.isGranted) {
        return false;
      }

      final calendars = await _calendarService.getCalendars();
      if (calendars.isEmpty) {
        print("No calendars found - using primary calendar");
        await prefs.setString('selected_calendar_id', 'primary');
        _calendarEnabled = true;
        _selectedCalendarId = 'primary';
        notifyListeners();
        return true;
      }

      final primaryCalendar = calendars.firstWhere(
        (cal) => cal.isPrimary, 
        orElse: () => calendars.first
      );
      
      await prefs.setString('selected_calendar_id', primaryCalendar.id);
      
      _calendarEnabled = true;
      _selectedCalendarId = primaryCalendar.id;
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error requesting calendar permissions: $e');
      return false;
    }
  }

  Future<void> revokeCalendarAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('calendar_was_previously_revoked', true);
      await prefs.setBool('calendar_access_revoked', true);
      await prefs.remove('selected_calendar_id');
      
      final authService = AuthService();
      await authService.revokeCalendarPermissions();
      
      _calendarEnabled = false;
      _selectedCalendarId = null;
      clearEventData();
      
      notifyListeners();
      
      print('Calendar permissions fully revoked');
    } catch (e) {
      print('Error revoking calendar access: $e');
      _calendarEnabled = false;
      _selectedCalendarId = null;
      clearEventData();
      notifyListeners();
    }
  }
}