import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/widgets/tags/tag.dart';
import 'package:chefoo/widgets/star_ratings/star_rating.dart';

class MealCardHorizontal extends StatefulWidget {
  final Place place;
  final List<Meal> meals;
  final bool disableNavigation; 

  MealCardHorizontal({
    Key? key,
    required this.place,
    required this.meals,
    this.disableNavigation = false,
  }) : super(key: key);

  @override
  State<MealCardHorizontal> createState() => _MealCardHorizontalState();
}

class _MealCardHorizontalState extends State<MealCardHorizontal> {
  final _banner = PictureCategoryAssets();
  int _currentIndex = 0;

  void _nextMeal() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.meals.length;
    });
  }

  void _previousMeal() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.meals.length) % widget.meals.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pictureUrl =
        _banner.pictureCategoryAssets[widget.place.pictureCategory] ??
            'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=400'
                '&photo_reference=${widget.place.pictureUrls.first}'
                '&key=${MapsConstants.mapsKey}';

    // Show current meal or null if list is empty
    final currentMeal =
        widget.meals.isNotEmpty ? widget.meals[_currentIndex] : null;

    return GestureDetector(
      onTap: () {
        // Only navigate if navigation is enabled
        if (!widget.disableNavigation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(place: widget.place),
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: 120,
          maxHeight: 145,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: 120,
              height: 120,
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
            // ... rest of your existing card content

            // Existing content section
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Restaurant name and tag in same row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.place.name,
                          style: AppTextStyles.headline3
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.place.tags.isNotEmpty) SizedBox(width: 4),
                      if (widget.place.tags.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: 100), // Limit maximum width
                          child: Tag(
                            label: widget.place.tags.first,
                            isLongPressable: false,
                            isTappable: false,
                            fontSize: 10,
                            backgroundColor:
                                AppColors.secondary.withOpacity(0.2),
                            labelMaxLines: 1,
                            labelOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Meal information if available
                  if (currentMeal != null) ...[
                    Container(
                      width: double.infinity,
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
                        currentMeal.name,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (currentMeal.notes.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 36),
                        child: Text(
                          currentMeal.notes,
                          style: AppTextStyles.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],

                  Spacer(),

                  // Bottom row with ratings and health score
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Star rating - updated to match RestaurantCardHorizontal
                      if (currentMeal != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StarRating(
                              rating: currentMeal.rating,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              currentMeal.rating.toStringAsFixed(1),
                              style: AppTextStyles.detail
                                  .copyWith(height: 1, fontSize: 16),
                            ),
                          ],
                        ),
                      Column(
                        children: [
                          if (currentMeal != null &&
                              currentMeal.analysis != null &&
                              currentMeal.analysis!.containsKey('healthyScore'))
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: _getHealthScoreColor(
                                      currentMeal.analysis!['healthyScore']),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${currentMeal.analysis!['healthyScore']}/100',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    color: _getHealthScoreColor(
                                        currentMeal.analysis!['healthyScore']),
                                  ),
                                ),
                              ],
                            )
                          else if (widget.place.walkingDistance > 0)
                            Text(
                              '${(widget.place.walkingDistance * 1000).round()}m',
                              style: AppTextStyles.detail,
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: _previousMeal,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${_currentIndex + 1}/${widget.meals.length}",
                                  style: AppTextStyles.caption,
                                ),
                                SizedBox(width: 8),
                                InkWell(
                                  onTap: _nextMeal,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  // Health score or walking distance (priority to health score)
                ],
              ),
            ),
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
