import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:provider/provider.dart';

class OtherRecomScreen extends StatelessWidget {
  final List<Place> places;

  const OtherRecomScreen({Key? key, required this.places}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    
    final displayPlaces = places.isNotEmpty 
        ? places 
        : restaurantProvider.routePlaces.isNotEmpty
            ? restaurantProvider.routePlaces
            : restaurantProvider.places;

    String screenTitle;

    final hasRoutePlaces = restaurantProvider.routePlaces.isNotEmpty &&
      displayPlaces.any((p) => restaurantProvider.routePlaces.any((rp) => rp.id == p.id));

    final hasNearbyPlaces = restaurantProvider.places.isNotEmpty && 
      displayPlaces.any((p) => restaurantProvider.places.any((np) => np.id == p.id));

    if (hasRoutePlaces && hasNearbyPlaces) {
      screenTitle = "Recommended Places";
    } else {
      screenTitle = "Places Near You";
    }
            
    if (displayPlaces.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Text(
            "No places found.\nTry exploring a different area!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 200,
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(
            initialItem: (displayPlaces.length / 2).floor(),
          ),
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= displayPlaces.length) return null;
              return RestaurantCardHorizontal(place: displayPlaces[index]);
            },
            childCount: displayPlaces.length,
          ),
        ),
      ),
    );
  }
}