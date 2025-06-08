import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:chefoo/widgets/cards/meal_card_horizontal.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Meal>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _mealsFuture = HistoryService().fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Meal History',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Meal>>(
                future: _mealsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final meals = snapshot.data ?? [];

                  if (meals.isEmpty) {
                    return const Center(child: Text('No meal history found.'));
                  }

                  final groupedMeals = <String, List<Meal>>{};
                  for (final meal in meals) {
                    final id = meal.restaurant.id;
                    groupedMeals.putIfAbsent(id, () => []).add(meal);
                  }

                  final recentEntries = groupedMeals.entries
                      .toList()
                      .reversed
                      .take(5)
                      .toList()
                      .reversed
                      .toList();

                  return Column(
                    children: recentEntries.map((entry) {
                      final place = entry.value.first.restaurant;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                        child: MealCardHorizontal(
                          place: place,
                          meals: entry.value,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
