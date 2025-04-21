import 'dart:convert';
import 'package:http/http.dart' as http;

class PopularTimesService {
  static const String baseUrl = 'http://localhost:3001';

  Future<List<Map<String, dynamic>>?> getPopularTimes(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/populartimes/$placeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['populartimes'] != null) {
          return List<Map<String, dynamic>>.from(data['populartimes']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching popular times: $e');
      return null;
    }
  }
}