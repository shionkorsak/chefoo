import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/screens/main/main_screen.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';
import 'package:chefoo/widgets/tags/unclickable_tag.dart';
import 'package:chefoo/widgets/buttons/circle_button.dart';
import 'package:chefoo/widgets/star_ratings/star_rating.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chefoo/constants.dart';

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
  final _banner = PictureCategoryAssets();

  @override
  void initState() {
    super.initState();
    _loadDetailedInfo();
    _loadPopularTimes();
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
    final banner = PictureCategoryAssets();
    final String? categoryImageUrl = banner.pictureCategoryAssets[widget.place.pictureCategory];
    final String headerImageUrl = categoryImageUrl ??
      'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=800'
          '&photo_reference=${widget.place.pictureUrls.first}'
          '&key=${MapsConstants.mapsKey}';
    return Scaffold(
      appBar: AppBar(
        //title: Text(widget.place.name),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            //child: LikeButton(place: widget.place),
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
                  if (headerImageUrl.isNotEmpty)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Outer stack for image and overlays
                        Stack(
                          children: [
                            Container(
                              height: 320,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(headerImageUrl),
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
                        // The overlay AuthCard has been removed as requested.
                      ],
                    ),
                  //const SizedBox(height: 100),
                  // if (widget.place.pictureUrls.isNotEmpty)
                  //   const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                      // final user = FirebaseAuth.instance.currentUser;
                                      // final uid = user?.uid;
                                      final uid = AuthService().getCurrentUserUID();

                                      if (uid == null) {
                                        print("User not logged in. Skipping session start.");
                                        return;
                                      }

                                      final ratingSession = Provider.of<RatingSessionProvider>(context, listen: false);
                                      ratingSession.startSession(
                                        id: widget.place.id,
                                        name: widget.place.name,
                                        photo: widget.place.pictureCategory,
                                        tags: widget.place.tags,
                                        uid: uid,
                                      );

                                      launchUrl(Uri.parse(
                                        'https://www.google.com/maps/dir/?api=1&destination=${widget.place.lat},${widget.place.lng}',
                                      ));
                                      Future.delayed(Duration(milliseconds: 300), () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => MainScreen(showWelcomeDialog: true,)),
                                          (route) => false,
                                        );
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  LikeButton(place: widget.place),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tags",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 40,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: widget.place.tags.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        return TagChip(
                                            label: widget.place.tags[index]);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  //const Divider(),
                                ],
                              ),
                              if (widget.place.openingHours != null &&
                                  widget.place.openingHours!.isNotEmpty) ...[
                                // Opening hours block: always start from Monday, expanded view reorders, no duplicate today entry
                                StatefulBuilder(
                                  builder: (context, setState) {
                                    final now = DateTime.now();
                                    final currentWeekdayIndex =
                                        now.weekday == 7 ? 6 : now.weekday - 1;
                                    bool isExpanded = false;
                                    // Reorder opening hours so Monday is first, Sunday is last
                                    final reorderedHours = List.generate(
                                      7,
                                      (index) => widget
                                          .place.openingHours![(index + 0) % 7],
                                    );
                                    return StatefulBuilder(
                                      builder: (context, innerSetState) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Opening Hours',
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    isExpanded
                                                        ? Icons
                                                            .keyboard_arrow_up
                                                        : Icons
                                                            .keyboard_arrow_down,
                                                  ),
                                                  onPressed: () {
                                                    innerSetState(() {
                                                      isExpanded = !isExpanded;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            AnimatedCrossFade(
                                              crossFadeState: isExpanded
                                                  ? CrossFadeState.showSecond
                                                  : CrossFadeState.showFirst,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              firstChild: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 120,
                                                      child: Text(
                                                        widget
                                                            .place
                                                            .openingHours![
                                                                currentWeekdayIndex]
                                                            .split(': ')[0],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      widget
                                                                  .place
                                                                  .openingHours![
                                                                      currentWeekdayIndex]
                                                                  .split(': ')
                                                                  .length >
                                                              1
                                                          ? widget
                                                              .place
                                                              .openingHours![
                                                                  currentWeekdayIndex]
                                                              .split(': ')[1]
                                                          : '',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              secondChild: Column(
                                                children: reorderedHours
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final index = entry.key;
                                                  final value = entry.value;
                                                  final trueIndex =
                                                      (index + 0) % 7;
                                                  final isToday = trueIndex ==
                                                      currentWeekdayIndex;
                                                  final parts =
                                                      value.split(': ');
                                                  final dayLabel = parts.first;
                                                  final hourRange =
                                                      parts.length > 1
                                                          ? parts[1]
                                                          : '';
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4.0),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 120,
                                                          child: Text(
                                                            dayLabel,
                                                            style: TextStyle(
                                                              fontWeight: isToday
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                              color: isToday
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          hourRange,
                                                          style: TextStyle(
                                                            fontWeight: isToday
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                            color: isToday
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors
                                                                    .textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            //const Divider(),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        //const SizedBox(width: 16),
                        // Right side: (tags card removed)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (_isLoadingPopularTimes ||
                            (widget.place.popularTimes != null &&
                                widget.place.popularTimes!.isNotEmpty)) ...[
                          if (_isLoadingPopularTimes)
                            const Center(child: CircularProgressIndicator())
                          else
                            AuthCard(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                Text(
                                  'Busy time',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 250,
                                  child: PopularTimesChart(
                                    popularTimes: widget.place.popularTimes!,
                                    openingHours: widget.place.openingHours,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          //const Divider(),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: kRadius30,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey.shade300,
                                        child: Text(
                                          review.authorName.isNotEmpty
                                              ? review.authorName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children:
                                                  List.generate(5, (index) {
                                                return Icon(
                                                  index < review.rating.round()
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              review.text,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              review.formattedTime,
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                          const SizedBox(height: 16),
                          //const Divider(),
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
                                child: Text('View All (${widget.place.pictureUrls.length - 1})'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: widget.place.pictureUrls.length > 1 
                                ? (widget.place.pictureUrls.length > 5 ? 4 : widget.place.pictureUrls.length - 1)
                                : 0,
                            itemBuilder: (context, index) {
                              final actualIndex = index + 1;
                              final imageUrl =
                                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${widget.place.pictureUrls[actualIndex]}&key=${MapsConstants.mapsKey}';
                              final isLast = index == 3 ||
                                  index == widget.place.pictureUrls.length - 2; // Adjusted for the offset

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PhotoGrid(
                                        photoRefs: widget.place.pictureUrls,
                                        initialIndex: actualIndex, // Use the actual index here
                                        placeName: widget.place.name,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2));
                                        },
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Center(
                                                child:
                                                    Icon(Icons.broken_image)),
                                      ),
                                      if (isLast)
                                        Container(
                                          color: Colors.black.withOpacity(0.5),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'See More',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
