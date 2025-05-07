import 'package:flutter/material.dart';

class ImagePreloader {
  static void preloadImages(BuildContext context, List<String> imageUrls) {
    for (final url in imageUrls) {
      precacheImage(NetworkImage(url), context);
    }
  }
}