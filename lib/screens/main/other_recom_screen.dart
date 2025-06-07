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
        body: Center(
          child: Text(
            "No places found.\nTry exploring a different area!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Text(
                  screenTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: displayPlaces.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RestaurantCardHorizontal(place: displayPlaces[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}