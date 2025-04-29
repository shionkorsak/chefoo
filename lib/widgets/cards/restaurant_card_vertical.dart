import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/buttons/like_button.dart';

class RestaurantCardVertical extends StatelessWidget {
  final Place place;
  const RestaurantCardVertical({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          LikeButton(isLiked: false),
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
              Text(place.tags.first) //TODO: fix error 
            ],
          )
        ],
      ),
    );
  }
}
