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
    final pictureUrl = place.pictureUrls.isNotEmpty ? place.pictureUrls.first : null;

    return Container(
      width: 130,
      height: 190,
      padding: kPadd10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: kRadius15,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          //LikeButton(isLiked: false),
          LikeButton(place: place),
          SizedBox(
            height: 24,
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
          SizedBox(height: 6),
          Row(
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
              Text(place.tags.isNotEmpty ? place.tags.first : 'No tags available'),
            ],
          ),
          SizedBox(height: 6),
          Expanded(
            child: isValidImageUrl(pictureUrl)
                ? Image.network(
                    pictureUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Image.asset('assets/images/placeholder.png', fit: BoxFit.cover);
                    },
                  )
                : Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
