import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:chefoo/constants.dart';

class RestaurantCardVertical extends StatelessWidget {
  final Place place;
  final _banner = PictureCategoryAssets();

  RestaurantCardVertical({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pictureUrl = _banner.pictureCategoryAssets[place.pictureCategory] 
    ?? 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=${place.pictureUrls.first}'
        '&key=${MapsConstants.mapsKey}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(place: place),
          ),
        );
        // [DATABASE]: same here. you can add the same function here so that
        // the place ID gets sent to database
        /*
          String placeId = place.id;
          saveToDatabase(placeId);
        */
      },
      child: Container(
        width: 200,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(
                width: double.infinity,
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
                      child: LikeButton(place: place),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              place.name,
              style: AppTextStyles.headline3
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Uncomment if you want to use Marquee instead of simple Text
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
            SizedBox(
              height: 2,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        Text(
                          place.rating.toString(),
                          style: AppTextStyles.detail
                              .copyWith(height: 1, fontSize: 14),
                        )
                      ],
                    ),
                    Text(
                      place.tags.isNotEmpty
                          ? place.tags.first
                          : 'No tags available',
                      style: AppTextStyles.detail,
                    ),
                  ],
                ),
                place.walkingDistance == 0
                ? const SizedBox.shrink()
                : Text(
                    '${(place.walkingDistance * 1000).round()}m',
                    style: AppTextStyles.detail,
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
