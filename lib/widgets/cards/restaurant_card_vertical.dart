import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';

class RestaurantCardVertical extends StatelessWidget {
  final Place place;
  const RestaurantCardVertical({
    Key? key,
    required this.place,
  }) : super(key: key);

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

    return Container(
      width: 130,
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
        children: [
          Container(
            height: 116,
            width: 116,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: kRadius10, // Use your existing border radius
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
          SizedBox(
            height: 28,
            width: double.infinity,
            child: Marquee(
              text: place.name,
              style: AppTextStyles.headline3
                  .copyWith(color: AppColors.textPrimary),
              scrollAxis: Axis.horizontal,
              blankSpace: 20.0,
              velocity: 30.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        size: 10,
                        color: AppColors.primary,
                      ),
                      Text(
                        place.rating.toString(),
                        style: AppTextStyles.detail.copyWith(height: 1),
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
              Text(
                '${place.walkingDistance.toStringAsFixed(1)}km',
                style: AppTextStyles.detail,
              )
            ],
          ),
        ],
      ),
    );
  }
}
