import 'package:flutter/material.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/widgets/cards/meal_card_vertical.dart';
import 'package:chefoo/models/user/meal.dart';
import 'package:provider/provider.dart';
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
        final groupedMeals = grouped.entries.toList().reversed.take(5).toList().reversed.toList();

        return SizedBox(
          height: 290,
          child: Container(
            clipBehavior: Clip.none,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              itemCount: groupedMeals.length,
              itemBuilder: (context, index) {
                final entry = groupedMeals[index];
                final place = entry.value.first.restaurant;
                final meal = entry.value.first;
                return Padding(
                  padding: EdgeInsets.only(right: 16, bottom: 6),
                  child: MealCardVertical(
                    place: place,
                    meal: meal,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
