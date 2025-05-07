import 'package:chefoo/commons.dart';
import 'package:chefoo/utils/img_preloader.dart';
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

    _preloadImages(context);

    return ListView.builder(
      itemCount: places.length,
      // itemBuilder: (context, index) => RestaurantCard(place: places[index]),
      itemBuilder: (context, index) =>
          Center(child: RestaurantCardVertical(place: places[index])),
    );
  }

  void _preloadImages(BuildContext context) {
    final urls = places
        .where((place) => place.pictureUrls.isNotEmpty)
        .map((place) => 'https://maps.googleapis.com/maps/api/place/photo'
            '?maxwidth=200'
            '&photo_reference=${place.pictureUrls[0]}'
            '&key=${MapsConstants.mapsKey}')
        .toList();

    ImagePreloader.preloadImages(context, urls);
  }
}
