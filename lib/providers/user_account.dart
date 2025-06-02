import 'package:flutter/material.dart';
import '../models/user/user_account.dart';
import '../services/database/user_account_service.dart';

class UserAccountProvider with ChangeNotifier {
  final _service = UserAccountService();

  UserAccount? _userAccount;
  String? _errorMessage;
  bool _isLoading = false;

  UserAccount? get userAccount => _userAccount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> fetchUserAccount() async {
    await _handleAsyncOperation(() async {
      _userAccount = await _service.fetchUserAccount();
      if (_userAccount == null) {
        _errorMessage = "User account not found.";
      }
    });
  }

  Future<void> watchUserAccountOnce() async {
    await _handleAsyncOperation(() async {
      _userAccount = await _service.watchUserAccountOnce();
      if (_userAccount == null) {
        _errorMessage = "User account not found.";
      }
    });
  }

  Future<bool> updateUserPreferences(
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    final success = await _service.updateUserPreferences(
      dietaryPreferences: dietaryPreferences,
      allergies: allergies,
    );

    if (success) {
      await fetchUserAccount();
    }

    return success;
  }

  Future<bool> addUserPreferences(
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    final success = await _service.addUserPreference(
      dietaryPreferences: dietaryPreferences,
      allergies: allergies,
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
}
