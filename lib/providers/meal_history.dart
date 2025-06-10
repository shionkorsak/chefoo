import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:flutter/material.dart';

class MealHistoryProvider with ChangeNotifier {
  List<Meal> _meals = [];
  bool _isLoading = false;
  String? _error;

  List<Meal> get meals => _meals;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String get errorMessage => _error ?? '';

  Future<void> fetchMeals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meals = await HistoryService().fetchMeals();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _meals = [];
    _error = null;
    notifyListeners();
  }

  Future<void> deleteMeal(String mealId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await HistoryService().deleteMealInput(mealId);

      _meals = _meals.where((meal) => meal.mealId != mealId).toList();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
