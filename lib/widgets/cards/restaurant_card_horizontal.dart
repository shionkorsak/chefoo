import 'package:chefoo/widgets/star_ratings/star_rating.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';

class RestaurantCardHorizontal extends StatelessWidget {
  final Place place;
  const RestaurantCardHorizontal({
    Key? key,
    required this.place,
  }) : super(key: key);

  // Define a safer way to check URLs
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pictureUrl =
        place.pictureUrls.isNotEmpty ? place.pictureUrls.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
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
                        'https://maps.googleapis.com/maps/api/place/photo'
                        '?maxwidth=400'
                        '&photo_reference=${pictureUrl}'
                        '&key=${MapsConstants.mapsKey}',
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
                    child: LikeButton(place: place),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12), // spacing between image and text
            Expanded(
              // <-- This constrains the text section
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTextStyles.headline2
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // SizedBox(
                  //   height: 28,
                  //   width: double.infinity,
                  //   child: Marquee(
                  //     text: place.name,
                  //     style: AppTextStyles.headline3
                  //         .copyWith(color: AppColors.textPrimary),
                  //     scrollAxis: Axis.horizontal,
                  //     blankSpace: 20.0,
                  //     velocity: 30.0,
                  //     pauseAfterRound: Duration(seconds: 1),
                  //     startPadding: 10.0,
                  //     accelerationDuration: Duration(seconds: 1),
                  //     accelerationCurve: Curves.linear,
                  //     decelerationDuration: Duration(milliseconds: 500),
                  //     decelerationCurve: Curves.easeOut,
                  //   ),
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StarRating(
                            rating: place.rating,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: AppTextStyles.detail
                                .copyWith(height: 1, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            place.tags.isNotEmpty
                                ? place.tags.first
                                : 'No tags available',
                            style: AppTextStyles.detail,
                          ),
                          Text(
                            '${place.walkingDistance.toStringAsFixed(1)}km',
                            style: AppTextStyles.detail,
                          )
                        ],
                      ),
                    ],
                  ),
                  Text(
                      "Suggest message. Suggesest message. Suggest message.Suggest message. Suggesest message. Suggest message.Suggest message. Suggesest message. Suggest message.",
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
