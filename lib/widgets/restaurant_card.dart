import 'package:flutter/material.dart';
import 'package:chefoo/constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/restaurant.dart';
import '../services/location.dart';
import '../services/maps.dart';
import 'popular_times_chart.dart';
import 'photo_grid.dart';
import 'restaurant_elements.dart';

class RestaurantCard extends StatefulWidget {
  final Place place;

  const RestaurantCard({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool _isLoadingPopularTimes = false;

  Future<void> _loadPopularTimesIfNeeded() async {
    if (widget.place.popularTimesLoaded) return;

    setState(() {
      _isLoadingPopularTimes = true;
    });

    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      await placeService.fetchPopularTimes(widget.place);
    } catch (e) {
      print('Error loading popular times: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPopularTimes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // [DATABASE]: here too. save to history when viewing a place
    // i think in this case youll have to wrap the Card in a GestureDetector to
    // make the relation that onTap: 
    // String placeId = place.id;
    // saveToDatabase(placeId);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadPopularTimesIfNeeded();
          }
        },
        title: RestaurantName(widget.place.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantAddress(widget.place.address),
            const SizedBox(height: 4),
            Row(
              children: [
                RestaurantRating(rating: widget.place.rating),
                const SizedBox(width: 8),
                RestaurantDistance(distanceKm: widget.place.walkingDistance),
                const SizedBox(width: 8),
                OpenStatusBadge(isOpen: widget.place.isOpenNow ?? false),
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
                if (widget.place.phone != null) ...[
                  Center(child: PhoneButton(phoneNumber: widget.place.phone!)),
                  const SizedBox(height: 16),
                ],
                if (widget.place.openingHours != null && widget.place.openingHours!.isNotEmpty) ...[
                  const Text(
                    'Opening Hours',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...widget.place.openingHours!.map((hour) => Text(hour)),
                  const SizedBox(height: 16),
                ],
                if (widget.place.popularTimes != null && widget.place.popularTimes!.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Popular Times'),
                    children: [
                      SizedBox(
                        height: 150,
                        child: PopularTimesChart(
                          popularTimes: widget.place.popularTimes!,
                          openingHours: widget.place.openingHours,
                        ),
                      ),
                    ],
                  ),
                ] else if (_isLoadingPopularTimes) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                ] else if (widget.place.popularTimesLoaded) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Popular times data not available'),
                  )
                ],
                if (widget.place.reviews.isNotEmpty) ...[
                  const Text(
                    'Reviews',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.place.reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
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
                              ),
                              Text(
                                review.formattedTime,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(review.text),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.place.pictureUrls.isNotEmpty) ...[
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
                            itemCount: widget.place.pictureUrls.length > 3 ? 3 : widget.place.pictureUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoGrid(
                                          photoRefs: widget.place.pictureUrls,
                                          placeName: widget.place.name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    'https://maps.googleapis.com/maps/api/place/photo'
                                    '?maxwidth=400'
                                    '&photo_reference=${widget.place.pictureUrls[index]}'
                                    '&key=${MapsConstants.mapsKey}',
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
                        if (widget.place.pictureUrls.length > 3)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoGrid(
                                    photoRefs: widget.place.pictureUrls,
                                    placeName: widget.place.name,
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
                                  '+${widget.place.pictureUrls.length - 3}',
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
                Center(child: DirectionsButton(lat: widget.place.lat, lng: widget.place.lng)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}