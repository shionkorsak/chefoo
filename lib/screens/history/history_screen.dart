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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Text(
                  'Meal History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Meal>>(
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: recentEntries.map((entry) {
                      final place = entry.value.first.restaurant;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MealCardHorizontal(
                          place: place,
                          meals: entry.value,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
