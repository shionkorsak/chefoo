import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/favorites.dart';
import 'package:chefoo/widgets/restaurant_list.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Favorites',
      child: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (favoritesProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Like some restaurants to see them here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return RestaurantList(
            places: favoritesProvider.favorites,
            isLoading: false,
          );
        },
      ),
    );
  }
}