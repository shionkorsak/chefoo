import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class StarRatingEditable extends StatefulWidget {
  final int rating;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;
  final ValueChanged<int>? onRatingChanged;

  const StarRatingEditable({
    Key? key,
    this.rating = 0,
    this.starCount = 5,
    this.size = 16,
    this.color = AppColors.primary,
    this.emptyColor = Colors.grey,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  State<StarRatingEditable> createState() => _StarRatingEditableState();
}

class _StarRatingEditableState extends State<StarRatingEditable> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  void _onStarTap(int index) {
    setState(() {
      _currentRating = index + 1;
    });
    if (widget.onRatingChanged != null) {
      widget.onRatingChanged!(_currentRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        return GestureDetector(
          onTap: () => _onStarTap(index),
          child: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: index < _currentRating ? widget.color : widget.emptyColor,
          ),
        );
      }),
    );
  }
}
