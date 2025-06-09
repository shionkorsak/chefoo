import 'package:chefoo/models/user/health_insight.dart';
import 'package:flutter/material.dart';
import '../models/user/user_account.dart';
import '../services/database/user_account_service.dart';

class UserAccountProvider with ChangeNotifier {
  final _service = UserAccountService();

  UserAccount? _userAccount;
  String? _errorMessage;
  bool _isLoading = false;

  UserAccount? get userAccount => _userAccount;
  HealthInsight? get healthInsight => _userAccount?.healthInsight;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  List<String> get dietaryTags =>
      _userAccount?.preferences?.dietaryPreferences ?? [];
  List<String> get dislikeTags => _userAccount?.preferences?.dislikedFood ?? [];
  List<String> get allergyTags => _userAccount?.preferences?.allergies ?? [];

  Future<void> fetchUserAccount() async {
    try {
      final result = await _service.fetchUserAccount();
      if (result != null) {
        _userAccount = result;
      } else {
        _errorMessage = "User account not found.";
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = "An error occurred: $e";
      notifyListeners();
    }
  }

  Future<void> watchUserAccountOnce() async {
    await _handleAsyncOperation(() async {
      _userAccount = await _service.watchUserAccountOnce();
      if (_userAccount == null) {
        _errorMessage = "User account not found.";
      }
    });
  }

  Future<bool> updateUserPreferences({
    required List<String> dietaryPreferences,
    required List<String> allergies,
    required List<String> dislikedFood,
  }) async {
    final success = await _service.updateUserPreferences(
      dietaryPreferences: dietaryPreferences,
      allergies: allergies,
      dislikedFood: dislikedFood,
    );
    if (success) {
      await fetchUserAccount();
    }
    return success;
  }

  Future<bool> addUserPreferences(
    List<String> dietaryPreferences,
    List<String> allergies,
    List<String> dislikedFood,
  ) async {
    final success = await _service.addUserPreference(
      dietaryPreferences: dietaryPreferences,
      allergies: allergies,
      dislikedFood: dislikedFood,
    );
    if (success) {
      await fetchUserAccount();
    }
    return success;
  }

  Future<void> _handleAsyncOperation(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
    } catch (e) {
      _errorMessage = "An error occurred: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHealthInsightOnly() async {
    _isLoading = true;
    notifyListeners();
    try {
      final insight = await _service.fetchHealthInsightOnly();
      if (_userAccount != null && insight != null) {
        _userAccount = UserAccount(
          profile: _userAccount!.profile,
          preferences: _userAccount!.preferences,
          healthInsight: insight,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch health insight: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addTag(String category, String tag) {
    if (_userAccount == null) return;
    final prefs = _userAccount!.preferences;
    switch (category) {
      case 'Dietary Preference':
        if (!prefs!.dietaryPreferences.contains(tag)) prefs!.dietaryPreferences.add(tag);
        break;
      case 'Dislike':
        if (!prefs!.dislikedFood.contains(tag)) prefs!.dislikedFood.add(tag);
        break;
      case 'Allergy':
        if (!prefs!.allergies.contains(tag)) prefs!.allergies.add(tag);
        break;
    }
    notifyListeners();
    _service.updateUserPreferences(
      dietaryPreferences: prefs!.dietaryPreferences,
      allergies: prefs.allergies,
      dislikedFood: prefs.dislikedFood,
    );
  }

  void removeTag(String category, String tag) {
    if (_userAccount == null) return;
    final prefs = _userAccount!.preferences;
    switch (category) {
      case 'Dietary Preference':
        prefs!.dietaryPreferences.remove(tag);
        break;
      case 'Dislike':
        prefs!.dislikedFood.remove(tag);
        break;
      case 'Allergy':
        prefs!.allergies.remove(tag);
        break;
    }
    notifyListeners();
    _service.updateUserPreferences(
      dietaryPreferences: prefs!.dietaryPreferences,
      allergies: prefs.allergies,
      dislikedFood: prefs.dislikedFood,
    );
  }

  void editTag(String category, String oldTag, String newTag) {
    if (_userAccount == null) return;
    final prefs = _userAccount!.preferences;
    List<String> list;
    switch (category) {
      case 'Dietary Preference':
        list = prefs!.dietaryPreferences;
        break;
      case 'Dislike':
        list = prefs!.dislikedFood;
        break;
      case 'Allergy':
        list = prefs!.allergies;
        break;
      default:
        return;
    }
    final index = list.indexOf(oldTag);
    if (index != -1) {
      list[index] = newTag;
      notifyListeners();
      _service.updateUserPreferences(
        dietaryPreferences: prefs!.dietaryPreferences,
        allergies: prefs.allergies,
        dislikedFood: prefs.dislikedFood,
      );
    }
  }
}
