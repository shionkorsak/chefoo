import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class PopularTimesService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';  // Special IP for Android emulator
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:3001';  // Use 127.0.0.1 instead of localhost
    }
    return 'http://localhost:3001';    // Fallback
  }

  Future<List<Map<String, dynamic>>?> getPopularTimes(String placeId) async {
    try {
      final url = Uri.parse('$baseUrl/api/populartimes/$placeId');
      print('Fetching popular times from: $url');
      
      // Add headers to handle CORS
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      ).timeout(
        const Duration(seconds: 30),  // Increased timeout
        onTimeout: () {
          print('Request timed out for $placeId');
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['populartimes'] != null) {
          print('Successfully got popular times for $placeId');
          return List<Map<String, dynamic>>.from(data['populartimes']);
        } else {
          print('No popular times data available for $placeId');
        }
      } else {
        print('Server error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    } on SocketException catch (e) {
      print('Network error: Make sure your server is running');
      print('Error details: $e');
      return null;
    } catch (e) {
      print('Error fetching popular times for $placeId: $e');
      return null;
    }
  }
}