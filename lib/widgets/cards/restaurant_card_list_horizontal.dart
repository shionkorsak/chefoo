import 'package:chefoo/widgets/cards/restaurant_card_vertical_without.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import 'restaurant_card_vertical.dart';

class RestaurantCardListHorizontal extends StatelessWidget {
  final bool without;
  final List<Place> places;
  final bool isLoading;

  const RestaurantCardListHorizontal({
    Key? key,
    required this.without,
    required this.places,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (places.isEmpty) {
      return const Center(child: Text('No restaurants found nearby'));
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: places.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 5.0),
        child: Center(child: RestaurantCardVertical(place: places[index])),
      ),
    );
  }
}
