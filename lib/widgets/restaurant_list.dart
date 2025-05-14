import 'package:flutter/material.dart';
import 'package:chefoo/widgets/cards/restaurant_card_vertical.dart';
import '../models/restaurant.dart';
import './restaurant_card.dart';

class RestaurantList extends StatelessWidget {
  final List<Place> places;
  final bool isLoading;

  const RestaurantList({
    Key? key,
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
      itemCount: places.length,
      itemBuilder: (context, index) => RestaurantCard(place: places[index]),
    );
  }
}
