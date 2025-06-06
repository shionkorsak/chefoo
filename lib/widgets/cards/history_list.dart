import 'package:flutter/material.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:chefoo/models/user/meal.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({Key? key}) : super(key: key);

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  late Future<List<Meal>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _mealsFuture = HistoryService().fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Meal>>(
      future: _mealsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final meals = snapshot.data ?? [];
        final places = meals.map((meal) => meal.restaurant).toSet().toList();

        if (places.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No history yet.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: RestaurantCardListHorizontal(
                without: true,
                places: places,
                isLoading: false,
              ),
            ),
          ],
        );
      },
    );
  }
}