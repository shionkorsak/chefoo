import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/models/user/meal.dart'; // Add this import

class MealCardVertical extends StatelessWidget {
  final Place place;
  final Meal? meal; // Add meal parameter
  final _banner = PictureCategoryAssets();

  MealCardVertical({
    Key? key,
    required this.place,
    this.meal, // Optional meal parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pictureUrl = _banner.pictureCategoryAssets[place.pictureCategory] ??
        'https://maps.googleapis.com/maps/api/place/photo'
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
      },
      child: Container(
        width: 200,
        constraints: BoxConstraints(
          minHeight: 230,
          maxHeight: 280,
        ),
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
            SizedBox(height: 8),
            Text(
              place.name,
              style: AppTextStyles.headline3
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),

            // Add meal information if available
            if (meal != null) ...[
              Container(
                width: double.infinity, // Ensure container takes full width
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  meal!.name,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 4),
              if (meal!.notes.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 36),
                  child: Text(
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                    style: AppTextStyles.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (meal!.analysis != null &&
                  meal!.analysis!.containsKey('healthyScore'))
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 12,
                      color:
                          _getHealthScoreColor(meal!.analysis!['healthyScore']),
                    ),
                    SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Health: ${meal!.analysis!['healthyScore']}/100',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: _getHealthScoreColor(
                              meal!.analysis!['healthyScore']),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],

            SizedBox(height: 4),
            // For tags row - ensure better space distribution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Star rating
                Flexible(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      Flexible(
                        child: Text(
                          place.rating.toString(),
                          style: AppTextStyles.detail
                              .copyWith(height: 1, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(width: 4),
                // Tag
                Flexible(
                  flex: 2,
                  child: Text(
                    place.tags.isNotEmpty
                        ? place.tags.first
                        : 'No tags available',
                    style: AppTextStyles.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            place.walkingDistance == 0
                ? const SizedBox.shrink()
                : Text(
                    '${(place.walkingDistance * 1000).round()}m',
                    style: AppTextStyles.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
          ],
        ),
      ),
    );
  }

  // Helper method to determine color based on health score
  Color _getHealthScoreColor(dynamic score) {
    if (score is! num) return Colors.grey;

    final numScore = score as num;
    if (numScore >= 80) return Colors.green;
    if (numScore >= 50) return Colors.orange;
    return Colors.red;
  }
}
