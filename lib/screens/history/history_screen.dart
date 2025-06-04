// import 'package:flutter/material.dart';
// import 'package:chefoo/commons.dart';
// import 'package:chefoo/widgets/cards/restaurant_card_horizontal.dart';
// import 'package:chefoo/models/restaurant.dart';

// class HistoryScreen extends StatelessWidget {
//   final List<Place> places;

//   const HistoryScreen({Key? key, required this.places}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("History"),
//         backgroundColor: AppColors.background,
//         elevation: 0,
//         foregroundColor: AppColors.primary,
//       ),
//       body: SizedBox(
//         height: MediaQuery.of(context).size.height - kToolbarHeight,
//         child: ListWheelScrollView.useDelegate(
//           itemExtent: 200,
//           physics: const FixedExtentScrollPhysics(),
//           controller: FixedExtentScrollController(
//             initialItem: (places.length / 2).floor(),
//           ),
//           childDelegate: ListWheelChildBuilderDelegate(
//             builder: (context, index) {
//               if (index < 0 || index >= places.length) return null;
//               return RestaurantCardHorizontal(place: places[index]);
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:chefoo/widgets/cards/restaurant_meal.dart';
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
        title: const Text('Meal History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Meal>>(
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

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: groupedMeals.entries.map((entry) {
              final place = entry.value.first.restaurant;
              return RestaurantMealCard(
                place: place,
                meals: entry.value,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
