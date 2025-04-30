import 'package:flutter_skeleton/commons.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;

  const LikeButton({
    super.key,
    required this.isLiked,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // TODO: implement add-favorite function here
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: Icon(widget.isLiked ? Icons.favorite : Icons.favorite_border,
            color: AppColors.surface, size: 16),
      ),
    );
  }
}
