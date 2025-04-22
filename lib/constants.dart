import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

///Here you can save all the "global" variables you might use in your app

///Global navigator key
final navigatorKey = GlobalKey<NavigatorState>();

abstract class MapsConstants {
  static Future<void> init() async {
    await dotenv.load();
  }
  static String get mapsKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';
}