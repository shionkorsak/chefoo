import 'package:chefoo/models/restaurant.dart';

class Meal {
  final String mealId;
  final DateTime time;
  final String name;
  final String notes;
  final double rating;
  final Place restaurant;
  final Map<String, dynamic>? analysis;

  Meal({
    required this.mealId,
    required this.time,
    required this.name,
    required this.notes,
    required this.rating,
    required this.restaurant,
    this.analysis,
  });

  factory Meal.fromFirestoreAndPlace({
    required Map<String, dynamic> data,
    required Place restaurant,
  }) {
    final profile = data['profile'] ?? {};
    final feedback = data['feedback'] ?? {};

    return Meal(
      mealId: profile['mealId'] ?? '',
      time: DateTime.parse(profile['time'] ?? DateTime.now().toIso8601String()),
      name: profile['name'] ?? '',
      notes: feedback['notes'] ?? '',
      rating: (feedback['rating'] ?? 0).toDouble(),
      analysis: data['analysis'],
      restaurant: restaurant,
    );
  }
}
