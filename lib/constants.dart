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

class AppConfig {
  static const int MAX_PLACES_TO_LOAD = 20; // TODO: change for final presentation
}

class PictureCategoryAssets {
  Map<String, String> get pictureCategoryAssets => _pictureCategoryAssets;

  static const Map<String, String> _pictureCategoryAssets = {
    'american_food': 'https://drive.google.com/uc?export=view&id=1g3CA0b_WXl-riKWZWJX6WsYjmM18XEL9',
    'beefnoodle_food': 'https://drive.google.com/uc?export=view&id=1Z_rJBNAQtgOCVjKJuEuo5Myh7WlrGmf1',
    'bento_food': 'https://drive.google.com/uc?export=view&id=1RkdRWPMd2PB3JNJJTq1NtsBle61nImpG',
    'chicken_rice': 'https://drive.google.com/uc?export=view&id=1NyVTtwLuDT76OvKy5A68dMwdW4PnwUnl',
    'curry': 'https://drive.google.com/uc?export=view&id=1741R_pLLSLxjLCfzaJstUzZhQLRlM',
    'dimsum_food': 'https://drive.google.com/uc?export=view&id=1ZK6yKaR5LsmF8VF1DcC0gbqWrGZM9WUT',
    'duck_rice': 'https://drive.google.com/uc?export=view&id=1B2pHte7bHnucik4g0vZfNZ_eiXPBIRzI',
    'hotpot_food': 'https://drive.google.com/uc?export=view&id=1J6Xs4zp9HttLrEZTXqqRObI6hoxx58it',
    'indian_food': 'https://drive.google.com/uc?export=view&id=1xUY3ov4NiFYEjoz_JmBaQhofrnkajfhs',
    'italian_food': 'https://drive.google.com/uc?export=view&id=1eZEJ2ico9_56_SaPXAgW14w27wtSJSwm',
    'korean_food': 'https://drive.google.com/uc?export=view&id=1LSvQt4zVawMUky6uIeGpo4-DdeoxuXHP',
    'mexican_food': 'https://drive.google.com/uc?export=view&id=1Md0FwpGr0OCxbBvD3_x3oORVr26XNxzu',
    'ramen_food': 'https://drive.google.com/uc?export=view&id=1kXROt_DomaOxoa36hL0O1eUw3HIHmxJi',
    'sushi': 'https://drive.google.com/uc?export=view&id=1LlaCplEKLjrU1tkz8XIr9kWToBRJ12pT',
    'thai_food': 'https://drive.google.com/uc?export=view&id=1uDfrXW7ohb2ndozyF3ke4HaHg24fY3hx',
    'vietnamese_food': 'https://drive.google.com/uc?export=view&id=1WWU9YBq3JKi1lwuTkMWl2wh1lCSCWRua',
    'vegetarian_food': 'https://drive.google.com/uc?export=view&id=1oIIx9IkiQU63sDqF6VosBMOpUGgFIWRT',
    'xiaolongbao_food': 'https://drive.google.com/uc?export=view&id=1l0tCBbvrF9cOvEt5L7zvQIJ-zOUbogn7',
    'yansuji_food': 'https://drive.google.com/uc?export=view&id=1oj4klVx60zaiUKx4nHN1l3Qq2DLtRxTQ',
    'default': 'https://drive.google.com/uc?export=view&id=1nrdA3JCPybcnxAFQSAp7m1jZXTSess3e'
  };
}