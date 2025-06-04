import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/star_ratings/star_rating.dart';
import 'package:chefoo/widgets/buttons/like_button.dart';
import 'package:chefoo/commons.dart';
import 'package:flutter/material.dart';

class RestaurantMealCard extends StatefulWidget {
  final Place place;
  final List<Meal> meals;
  final bool isLoading;

  const RestaurantMealCard({
    Key? key,
    required this.place,
    required this.meals,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<RestaurantMealCard> createState() => _RestaurantMealCardState();
}

class _RestaurantMealCardState extends State<RestaurantMealCard> {
  final _banner = PictureCategoryAssets();
  int _currentMealIndex = 0;

  void _goToPrevious() {
    if (_currentMealIndex > 0) {
      setState(() {
        _currentMealIndex--;
      });
    }
  }

  void _goToNext() {
    if (_currentMealIndex < widget.meals.length - 1) {
      setState(() {
        _currentMealIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pictureUrl = _banner.pictureCategoryAssets[widget.place.pictureCategory] ??
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${widget.place.pictureUrls.first}&key=${MapsConstants.mapsKey}';

    final Meal? currentMeal = widget.meals.isNotEmpty ? widget.meals[_currentMealIndex] : null;

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
                        pictureUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Placeholder();
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StarRating(rating: widget.place.rating, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.place.rating.toStringAsFixed(1),
                            style: AppTextStyles.detail.copyWith(height: 1, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.place.tags.isNotEmpty ? widget.place.tags.first : 'No tags available',
                            style: AppTextStyles.detail,
                          ),
                          Text(
                            '${(widget.place.walkingDistance * 1000).round()}m',
                            style: AppTextStyles.detail,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (currentMeal != null) ...[
                    Text(
                      '${currentMeal.name}',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${currentMeal.notes}',
                      style: AppTextStyles.caption,
                    ),
                    if (currentMeal.analysis != null) ...[
                      Text(
                        'Tags: ${(currentMeal.analysis!['tags'] as List<dynamic>).join(", ")}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        'Score: ${currentMeal.analysis!['healthyScore']} / 100',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _goToPrevious,
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                        ),
                        Text('${_currentMealIndex + 1} / ${widget.meals.length}', style: AppTextStyles.caption),
                        IconButton(
                          onPressed: _goToNext,
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    )
                  ] else
                    const Text('No meals yet.', style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
