import 'dart:convert';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'package:chefoo/services/auth/auth_service.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['summary'] ?? 'No Title',
      location: json['location'] ?? '',
      startTime: DateTime.parse(json['start']['dateTime'] ?? json['start']['date']),
      endTime: DateTime.parse(json['end']['dateTime'] ?? json['end']['date']),
    );
  }
}

class CalendarService {
  final AuthService _authService = AuthService();
  
  Future<ApiResponse<CalendarEvent?>> getNextEvent({bool forceRefresh = false}) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return ApiResponse(
          success: false,
          message: 'User not signed in',
          error: 'Authentication required',
        );
      }
      
      GoogleSignInAccount? account = _authService.googleSignIn.currentUser;
      
      if (account == null) {
        account = await _authService.googleSignIn.signInSilently();
        
        if (account == null) {
          return ApiResponse(
            success: false,
            message: 'Google Sign-in required for calendar',
            error: 'Not signed in with Google',
          );
        }
      }
      
      final auth = await account.authentication;
      
      if (auth.accessToken == null) {
        return ApiResponse(
          success: false,
          message: 'Failed to get access token',
          error: 'Authentication error',
        );
      }
      
      final now = DateTime.now().toUtc().toIso8601String();
      
      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?maxResults=10'
        '&orderBy=startTime'
        '&singleEvents=true'
        '&timeMin=$now'
      );
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      );
      
      if (response.statusCode != 200) {
        return ApiResponse(
          success: false,
          message: 'API Error: ${response.statusCode}',
          error: response.body,
        );
      }
      
      final data = json.decode(response.body);
      final events = data['items'] as List;
      
      for (var event in events) {
        if (event['location'] != null && event['location'].toString().isNotEmpty) {
          return ApiResponse(
            success: true,
            message: 'Event found',
            data: CalendarEvent.fromJson(event),
          );
        }
      }
      
      return ApiResponse(
        success: true,
        message: 'No events with location found',
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error getting next event',
        error: e.toString(),
      );
    }
  }
  // user preferences are saved to the databse
  Future<bool> updateCalendarIntegrationStatus({
    required bool enabled,
    String? calendarId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      String? primaryCalendarId = calendarId;
      if (enabled && primaryCalendarId == null) {
        primaryCalendarId = 'primary';
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile.calendarEnabled': enabled,
        'profile.lastSyncTime': FieldValue.serverTimestamp(),
        'profile.primaryCalendarId': primaryCalendarId,
      });
      
      print('Calendar integration status updated: enabled=$enabled, calendarId=$primaryCalendarId');
      return true;
    } catch (e) {
      print('Error updating calendar integration status: $e');
      return false;
    }
  }

  // settings/preferences idk are retrieved from database
  Future<Map<String, dynamic>> getCalendarIntegrationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'calendarEnabled': false,
          'primaryCalendarId': null,
          'lastSyncTime': null
        };
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!doc.exists || doc.data() == null) {
        return {
          'calendarEnabled': false,
          'primaryCalendarId': null,
          'lastSyncTime': null
        };
      }
      
      // app state kept in sync w database
      final profile = doc.data()!['profile'] ?? {};
      return {
        'calendarEnabled': profile['calendarEnabled'] ?? false,
        'primaryCalendarId': profile['primaryCalendarId'],
        'lastSyncTime': profile['lastSyncTime']
      };
    } catch (e) {
      print('Error getting calendar integration status: $e');
      return {
        'calendarEnabled': false,
        'primaryCalendarId': null,
        'lastSyncTime': null
      };
    }
  }

  // sync calendar state with user profile
  Future<void> syncCalendarStateWithProfile(BuildContext context) async {
    try {
      final calendarStatus = await getCalendarIntegrationStatus();
      final calendarState = Provider.of<CalendarStateProvider>(context, listen: false);
      
      calendarState.setCalendarEnabled(calendarStatus['calendarEnabled'] ?? false);
      
      if (calendarStatus['primaryCalendarId'] != null) {
        calendarState.setSelectedCalendarId(calendarStatus['primaryCalendarId']);
      }
      
      print('Calendar state synced with user profile');
    } catch (e) {
      print('Error syncing calendar state: $e');
    }
  }
}