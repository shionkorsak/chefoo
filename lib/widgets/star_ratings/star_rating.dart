import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;

  const StarRating({
    Key? key,
    required this.rating,
    this.starCount = 5,
    this.size = 16,
    this.color = AppColors.primary,
    this.emptyColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star, size: size, color: color);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          // Half star
          return Icon(Icons.star_half, size: size, color: color);
        } else {
          // Empty star
          return Icon(Icons.star_border, size: size, color: emptyColor);
        }
      }),
    );
  }
}
