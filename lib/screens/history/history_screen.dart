import 'package:badges/badges.dart' as badges;
import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:chefoo/styles/colors.dart';
import 'package:chefoo/widgets/cards/meal_card_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:chefoo/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Meal>> _mealsFuture;
  bool _isEditMode = false;

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
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
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
                      final card = MealCardHorizontal(
                        place: place,
                        meals: entry.value,
                        disableNavigation:
                            _isEditMode, // Disable navigation in edit mode
                      );

                      // Apply badge in edit mode
                      if (_isEditMode) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 16, right: 16, left: 16),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // The card remains the same size
                              card,
                              // Position the badge on top of the card
                              Positioned(
                                top: -5,
                                left: -5,
                                child: GestureDetector(
                                  onTap: () {
                                    // Handle deletion here
                                    print(
                                        'Would delete meal: ${entry.value.first.name}');
                                    // Add actual deletion implementation later
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surface,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Regular card without badge
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 16, right: 16, left: 16),
                          child: card,
                        );
                      }
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
