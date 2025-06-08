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
      screenTitle = "Recommendations";
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
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  screenTitle,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
            ],
          ),
        ),
      ),
    );
  }
}