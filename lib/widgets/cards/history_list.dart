import 'package:flutter/material.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/cards/meal_card_vertical.dart';
import 'package:chefoo/models/user/meal.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/main_screen.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({Key? key}) : super(key: key);

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainScreenProvider>(
      builder: (context, provider, child) {
        final meals = provider.allMeals;
        if (meals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No history yet.'),
          );
        }

        final grouped = <String, List<Meal>>{};
        for (final meal in meals) {
          final id = meal.restaurant.id;
          grouped.putIfAbsent(id, () => []).add(meal);
        }
        final groupedMeals = grouped.entries.toList().reversed.take(5).toList().reversed.toList();

        return SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            itemCount: groupedMeals.length,
            itemBuilder: (context, index) {
              final entry = groupedMeals[index];
              final place = entry.value.first.restaurant;
              final meal = entry.value.first;
              return Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 6),
                child: MealCardVertical(
                  place: place,
                  meal: meal,
                ),
              );
            },
          ),
        );
      },
    );
  }
}