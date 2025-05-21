import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
import 'package:chefoo/models/restaurant.dart';

class HistoryScreen extends StatelessWidget {
  final List<Place> places;

  const HistoryScreen({Key? key, required this.places}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
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
            initialItem: (places.length / 2).floor(),
          ),
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= places.length) return null;
              return RestaurantCardHorizontal(place: places[index]);
            },
          ),
        ),
      ),
    );
  }
}
