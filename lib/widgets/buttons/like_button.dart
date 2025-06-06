import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/favorites.dart';

class LikeButton extends StatelessWidget {
  final Place? place;
  final bool isLiked;
  final double iconSize;
  final double padding;

  const LikeButton({
    Key? key,
    this.place,
    this.isLiked = false,
    this.iconSize = 16,
    this.padding = 6,
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
                    ? 'Removed from favorites' 
                    : 'Added to favorites'
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
        // [DATABASE]: here needs editing too. you or i will have
        // to get rid of the provider thing i have implemented above
        /* 
          String placeId = place.id;

          final isFav = await placeDatabase.isFav(place.id);
          if(isFav) {
            await placeDatabase.removeFav(place.id);
          } else {
            await placeDatabase.saveFav(place.id);
          }
        */
      },
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Icon(
            actualIsLiked ? Icons.favorite : Icons.favorite_border,
            color: AppColors.surface, 
            size: iconSize,
            key: ValueKey(actualIsLiked),
          ),
        ),
      ),
    );
  }
}
