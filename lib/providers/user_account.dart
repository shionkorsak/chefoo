import 'package:flutter/material.dart';
import '../models/user/user_account.dart';
import '../services/database/user_account_service.dart';

class UserAccountProvider with ChangeNotifier {
    final UserAccountService _service = UserAccountService();
    UserAccount? _userAccount;
    String? _errorMessage;
    bool _isLoading = false;

    UserAccount? get userAccount => _userAccount;
    String? get errorMessage => _errorMessage;
    bool get isLoading => _isLoading;

    Future<void> fetchUserAccount() async {
        _isLoading = true;
        notifyListeners();
        try {
            _userAccount = await _service.fetchUserAccount();
            if (_userAccount == null) {
                _errorMessage = "User account not found";
            }
        } catch (e) {
            _errorMessage = "Failed to load user account: $e";
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    Future<bool> updateUserPreferences(List<String> dietaryPreferences, List<String> allergies) async {
        final success = await _service.updateUserPreferences(
            dietaryPreferences: dietaryPreferences,
            allergies: allergies,
        );

        if (success) {
            await fetchUserAccount();
        }

        return success;
    }
}
