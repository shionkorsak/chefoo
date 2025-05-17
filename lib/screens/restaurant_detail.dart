import 'package:chefoo/commons.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Place place;

  const RestaurantDetailScreen({Key? key, required this.place}) : super(key: key);

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
        title: Text(widget.place.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: LikeButton(place: widget.place),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
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
                  child: Container(
                    height: 200,
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
                ),
                
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.place.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        OpenStatusBadge(isOpen: widget.place.isOpenNow ?? false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    RestaurantAddress(widget.place.address),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        RestaurantRating(rating: widget.place.rating),
                        const SizedBox(width: 16),
                        RestaurantDistance(distanceKm: widget.place.walkingDistance),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.place.phone != null)
                          PhoneButton(phoneNumber: widget.place.phone!),
                        DirectionsButton(lat: widget.place.lat, lng: widget.place.lng),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    
                    if (widget.place.openingHours != null && widget.place.openingHours!.isNotEmpty) ...[
                      const Text(
                        'Opening Hours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...widget.place.openingHours!.map((hour) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(hour),
                      )),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                    
                    if (_isLoadingPopularTimes || (widget.place.popularTimes != null && widget.place.popularTimes!.isNotEmpty)) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Popular Times',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    
                    if (_detailsLoaded && widget.place.reviews.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      )),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                    
                    if (_detailsLoaded && widget.place.pictureUrls.length > 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            child: Text('View All (${widget.place.pictureUrls.length})'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.place.pictureUrls.length > 5 ? 5 : widget.place.pictureUrls.length,
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