import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/restaurant.dart';
import '../services/location.dart';
import 'popular_times_chart.dart';
import 'photo_grid.dart';

class RestaurantCard extends StatelessWidget {
  final Place place;

  const RestaurantCard({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(place.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.address),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                Text('${place.rating}'),
                const SizedBox(width: 8),
                Icon(Icons.directions_walk, size: 16),
                Text('${place.walkingDistance.toStringAsFixed(1)}km'),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (place.phone != null) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:${place.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(place.phone!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (place.openingHours != null && place.openingHours!.isNotEmpty) ...[
                  const Text(
                    'Opening Hours',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...place.openingHours!.map((hour) => Text(hour)),
                  const SizedBox(height: 16),
                ],
                if (place.popularTimes != null && place.popularTimes!.isNotEmpty) ...[
                  PopularTimesChart(popularTimes: place.popularTimes!),
                  const SizedBox(height: 16),
                ],
                if (place.reviews.isNotEmpty) ...[
                  const Text(
                    'Reviews',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...place.reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.authorName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Text('${review.rating}'),
                              const Icon(Icons.star, size: 16),
                            ],
                          ),
                          Text(review.text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (place.pictureUrls.isNotEmpty) ...[
                  const Text(
                    'Photos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: place.pictureUrls.length > 3 ? 3 : place.pictureUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoGrid(
                                          photoRefs: place.pictureUrls,
                                          placeName: place.name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    'https://maps.googleapis.com/maps/api/place/photo'
                                    '?maxwidth=400'
                                    '&photo_reference=${place.pictureUrls[index]}'
                                    '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (place.pictureUrls.length > 3)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoGrid(
                                    photoRefs: place.pictureUrls,
                                    placeName: place.name,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.black54,
                              child: Center(
                                child: Text(
                                  '+${place.pictureUrls.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}&travelmode=walking'
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}