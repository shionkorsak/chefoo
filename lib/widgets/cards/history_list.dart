import 'package:flutter/material.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/cards/meal_card_vertical.dart';
import 'package:chefoo/models/user/meal.dart';
import 'package:provider/provider.dart';
import 'package:chefoo/providers/main_screen.dart';
import 'package:chefoo/providers/meal_history.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MealHistoryProvider>(
      builder: (context, provider, _) {
        final meals = provider.meals;

        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        if (provider.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${provider.errorMessage}'),
          );
        }

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
        final groupedMeals = grouped.entries
            .toList()
            .reversed
            .take(5)
            .toList()
            .reversed
            .toList();


        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: groupedMeals.map((entry) {
              final place = entry.value.first.restaurant;
              final meal = entry.value.first;
              return Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 12, 12),

                child: MealCardVertical(
                  place: place,
                  meal: meal,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
