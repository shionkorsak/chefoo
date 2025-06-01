import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';

class RestaurantName extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const RestaurantName(this.name, {Key? key, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: style ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class RestaurantAddress extends StatelessWidget {
  final String address;
  final TextStyle? style;

  const RestaurantAddress(this.address, {Key? key, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(address, style: style);
  }
}

class RestaurantRating extends StatelessWidget {
  final double rating;
  final double iconSize;
  final Color? iconColor;

  const RestaurantRating({
    Key? key,
    required this.rating,
    this.iconSize = 16,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: iconSize, color: iconColor ?? Colors.amber[700]),
        Text(rating.toStringAsFixed(1)),
      ],
    );
  }
}

class RestaurantDistance extends StatelessWidget {
  final double distanceKm;
  final double iconSize;

  const RestaurantDistance({
    Key? key,
    required this.distanceKm,
    this.iconSize = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDistance = distanceKm >= 1.0
        ? '${distanceKm.toStringAsFixed(1)}km'
        : '${(distanceKm * 1000).round()}m';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_walk, size: iconSize),
        Text(formattedDistance),
      ],
    );
  }
}

class OpenStatusBadge extends StatelessWidget {
  final bool isOpen;

  const OpenStatusBadge({Key? key, required this.isOpen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          fontSize: 12,
          color: isOpen ? Colors.green[900] : Colors.red[900],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PhoneButton extends StatelessWidget {
  final String phoneNumber;

  const PhoneButton({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uri = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      icon: const Icon(Icons.phone),
      label: Text(phoneNumber),
    );
  }
}

class DirectionsButton extends StatelessWidget {
  final double lat;
  final double lng;

  const DirectionsButton({
    Key? key,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking'
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.directions_walk),
      label: const Text('Directions'),
    );
  }
}

class RestaurantPhoto extends StatelessWidget {
  final String photoRef;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RestaurantPhoto({
    Key? key,
    required this.photoRef,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://maps.googleapis.com/maps/api/place/photo'
      '?maxwidth=200'
      '&photo_reference=$photoRef'
      '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
      cacheWidth: 200,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }
}