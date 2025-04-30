import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/favorites.dart';

class LikeButton extends StatelessWidget {
  final Place? place;
  final bool isLiked;

  const LikeButton({
    Key? key,
    this.place,
    this.isLiked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actualIsLiked = place != null 
        ? Provider.of<FavoritesProvider>(context).isFavorite(place!.id)
        : isLiked;
    
    return GestureDetector(
      onTap: () {
        if (place != null) {
          final provider = Provider.of<FavoritesProvider>(context, listen: false);
          provider.toggleFavorite(place!);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.isFavorite(place!.id) 
                    ? 'Added to favorites' 
                    : 'Removed from favorites'
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Icon(
            actualIsLiked ? Icons.favorite : Icons.favorite_border,
            color: AppColors.surface, 
            size: 16,
            key: ValueKey(actualIsLiked),
          ),
        ),
      ),
    );
  }
}
