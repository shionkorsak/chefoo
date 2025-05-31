import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/tags/unclickable_tag.dart';
import 'package:chefoo/widgets/buttons/circle_button.dart';
import 'package:chefoo/widgets/star_ratings/star_rating.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Place place;

  const RestaurantDetailScreen({Key? key, required this.place})
      : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isLoading = false;
  bool _isLoadingPopularTimes = false;
  bool _detailsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDetailedInfo();
    _loadPopularTimes();

    // [DATABASE]: here too. save to history when viewing a place
    // String placeId = place.id;
    // saveToDatabase(placeId);
  }

  Future<void> _loadDetailedInfo() async {
    if (widget.place.detailsLoaded) {
      setState(() {
        _detailsLoaded = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      await placeService.loadPlaceDetails(widget.place);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _detailsLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading place details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _detailsLoaded = false;
        });
      }
    }
  }

  Future<void> _loadPopularTimes() async {
    if (widget.place.popularTimesLoaded) return;

    setState(() {
      _isLoadingPopularTimes = true;
    });

    try {
      final placeService = Provider.of<PlaceService>(context, listen: false);
      await placeService.fetchPopularTimes(widget.place);

      if (mounted) {
        setState(() {
          _isLoadingPopularTimes = false;
        });
      }
    } catch (e) {
      print('Error loading popular times: $e');
      if (mounted) {
        setState(() {
          _isLoadingPopularTimes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text(widget.place.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: LikeButton(place: widget.place),
          ),
        ],
        leading: const BackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.place.pictureUrls.isNotEmpty)
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
                      child: Stack(
                        children: [
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://maps.googleapis.com/maps/api/place/photo'
                                  '?maxwidth=800'
                                  '&photo_reference=${widget.place.pictureUrls.first}'
                                  '&key=${MapsConstants.mapsKey}',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Row(
                              children: [
                                ActionCircleButton(
                                  icon: Icons.share,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.8),
                                  iconColor: AppColors.primary,
                                  onPressed: () {
                                    // TODO: Share functionality
                                  },
                                ),
                                SizedBox(width: 12),
                                ActionCircleButton(
                                  icon: Icons.chat_bubble_outline,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.8),
                                  iconColor: AppColors.primary,
                                  onPressed: () {
                                    // TODO: Chat or review action
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.place.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        OpenStatusBadge(isOpen: widget.place.isOpenNow ?? false),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side: Title, rating, distance, address, buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Text(
                              //   widget.place.name,
                              //   style:
                              //       Theme.of(context).textTheme.headlineSmall,
                              // ),
                              //const SizedBox(height: 8),
                              Row(
                                children: [
                                  StarRating(rating: widget.place.rating),
                                  const SizedBox(width: 8),
                                  RestaurantDistance(
                                      distanceKm: widget.place.walkingDistance),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RestaurantAddress(widget.place.address),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ActionCircleButton(
                                    icon: Icons.phone,
                                    onPressed: () {
                                      if (widget.place.phone != null) {
                                        launchUrl(Uri.parse(
                                            'tel:${widget.place.phone!}'));
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  ActionCircleButton(
                                    icon: Icons.navigation,
                                    onPressed: () {
                                      launchUrl(Uri.parse(
                                        'https://www.google.com/maps/dir/?api=1&destination=${widget.place.lat},${widget.place.lng}',
                                      ));
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  LikeButton(place: widget.place),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right side: Tags card
                        Expanded(
                          child: AuthCard(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            children: [
                              Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: widget.place.tags
                                    .map((tag) => TagChip(label: tag))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.place.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            OpenStatusBadge(
                                isOpen: widget.place.isOpenNow ?? false),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RestaurantAddress(widget.place.address),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            StarRating(rating: widget.place.rating),
                            const SizedBox(width: 16),
                            RestaurantDistance(
                                distanceKm: widget.place.walkingDistance),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.place.phone != null)
                              PhoneButton(phoneNumber: widget.place.phone!),
                            DirectionsButton(
                                lat: widget.place.lat, lng: widget.place.lng),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        if (widget.place.openingHours != null &&
                            widget.place.openingHours!.isNotEmpty) ...[
                          const Text(
                            'Opening Hours',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...widget.place.openingHours!.map((hour) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(hour),
                              )),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                        if (_isLoadingPopularTimes ||
                            (widget.place.popularTimes != null &&
                                widget.place.popularTimes!.isNotEmpty)) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Popular Times',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingPopularTimes)
                            const Center(child: CircularProgressIndicator())
                          else
                            SizedBox(
                              height: 200,
                              child: PopularTimesChart(
                                popularTimes: widget.place.popularTimes!,
                                openingHours: widget.place.openingHours,
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                        if (_detailsLoaded &&
                            widget.place.reviews.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reviews',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('${widget.place.reviews.length} reviews'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...widget.place.reviews.map((review) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                review.authorName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
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
                              )),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                        if (_detailsLoaded &&
                            widget.place.pictureUrls.length > 1) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Photos',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
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
                                child: Text(
                                    'View All (${widget.place.pictureUrls.length})'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.place.pictureUrls.length > 5
                                  ? 5
                                  : widget.place.pictureUrls.length,
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
                                            initialIndex: index,
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                              Icons.image_not_supported),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
