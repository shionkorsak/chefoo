import 'package:chefoo/widgets/star_ratings/star_rating.dart';
import 'package:chefoo/widgets/tags/tag.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/utils/place_utils.dart';
import 'package:chefoo/screens/restaurant_detail.dart'; // Add this import

class RestaurantCardHorizontal extends StatefulWidget {
  RestaurantCardHorizontal({
    Key? key,
    required this.place,
    this.isLoading = false,
    this.showDistance = true, 
  }) : super(key: key);

  final bool isLoading;
  final Place place;
  final bool showDistance;

  @override
  _RestaurantCardHorizontalState createState() =>
      _RestaurantCardHorizontalState();
}

class _RestaurantCardHorizontalState extends State<RestaurantCardHorizontal> {
  final _banner = PictureCategoryAssets();

  @override
  void initState() {
    super.initState();
    if (!widget.place.popularTimesLoaded) {
      Provider.of<PlaceService>(context, listen: false)
          .fetchPopularTimes(widget.place)
          .then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = Provider.of<LocationService>(context);
    final position = locationService.currentPosition;

    if (position != null) {
      final distance = calculateGeoDistance(
        position.latitude,
        position.longitude,
        widget.place.lat,
        widget.place.lng,
      );

      setState(() {
        widget.place.walkingDistance = distance / 1000;
      });
    }
  }

  Widget buildCrowdednessIndicator() {
    // Get crowdedness status
    final crowdednessStatus = PlaceUtils.getCrowdednessStatus(widget.place);

    if (!widget.place.popularTimesLoaded) {
      return Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 4),
          Text("Loading...", style: AppTextStyles.detail),
        ],
      );
    } else if (crowdednessStatus != null) {
      // Removed the Padding wrapper to fix alignment
      return Tag(
        label: _getCrowdednessText(crowdednessStatus),
        isLongPressable: false,
        isTappable: false,
        fontSize: 10,
        backgroundColor:
            _getCrowdednessColor(crowdednessStatus).withOpacity(0.2),
        selectedBorderColor: _getCrowdednessColor(crowdednessStatus),
      );
    }
    return SizedBox.shrink();
  }

  Widget buildOpeningHours() {
    if (widget.place.openingHours == null ||
        widget.place.openingHours!.isEmpty) {
      return SizedBox.shrink();
    }

    try {
      final now = DateTime.now();
      final dayIndex = now.weekday % 7;
      final weekdayTexts = widget.place.openingHours!;

      if (weekdayTexts.isEmpty || weekdayTexts.length <= dayIndex) {
        return SizedBox.shrink();
      }

      final fullHours = weekdayTexts[dayIndex];
      final parts = fullHours.split(': ');

      if (parts.length > 1) {
        final hoursText = parts[1].trim();

        if (hoursText.toLowerCase() == 'closed') {
          return Text('Today: Closed', style: AppTextStyles.detail);
        }

        return Text(
          'Open Hours: $hoursText',
          style: AppTextStyles.detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return SizedBox.shrink();
    } catch (e) {
      print('Error formatting opening hours: $e');
      return SizedBox.shrink();
    }
  }

  Color _getCrowdednessColor(String status) {
    switch (status) {
      case "empty":
        return Colors.green;
      case "normal":
        return Colors.orange;
      case "crowded":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCrowdednessText(String status) {
    switch (status) {
      case "empty":
        return "Not Busy";
      case "normal":
        return "Moderately Busy";
      case "crowded":
        return "Very Busy";
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    print('place.pictureCategory = ${widget.place.pictureCategory}');
    print('_banner has keys: ${_banner.pictureCategoryAssets.keys}');

    final pictureUrl =
        _banner.pictureCategoryAssets[widget.place.pictureCategory] ??
            'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400'
                '&photo_reference=${widget.place.pictureUrls.first}'
                '&key=${MapsConstants.mapsKey}';

    print('pictureUrl: $pictureUrl');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(place: widget.place),
          ),
        );
      },
      child: Container(
        padding: kPadd10,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: kRadius15,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 116,
              width: 116,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: kRadius10,
                      child: Image.network(
                        pictureUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Placeholder();
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: LikeButton(place: widget.place),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12), // spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: AppTextStyles.headline2
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StarRating(
                            rating: widget.place.rating,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.place.rating.toStringAsFixed(1),
                            style: AppTextStyles.detail
                                .copyWith(height: 1, fontSize: 16),
                          ),
                        ],
                      ),
                      widget.showDistance
                          ? Text(
                              '${(widget.place.walkingDistance * 1000).round()}m',
                              style: AppTextStyles.detail,
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  Wrap(
                    spacing: 8.0, // Horizontal space between tags
                    runSpacing: 4.0, // Vertical space between rows
                    children: [
                      if (widget.place.tags.isNotEmpty)
                        Tag(
                          label: widget.place.tags[0],
                          isLongPressable: false,
                          isTappable: false,
                          fontSize: 10,
                          selected: false,
                          backgroundColor: AppColors.secondary.withOpacity(0.2),
                        ),
                      buildCrowdednessIndicator(),
                    ],
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  buildOpeningHours(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
