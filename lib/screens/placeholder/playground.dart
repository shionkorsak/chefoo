import 'package:chefoo/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user/user_account.dart';
import '../../providers/user_account.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _dietaryController = TextEditingController();
  final _allergiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<UserAccountProvider>(context, listen: false).fetchUserAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: Consumer<UserAccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return Center(child: CircularProgressIndicator());
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red)));
          }

          final account = provider.userAccount;
          if (account == null) return Center(child: Text("No user data available."));

          _dietaryController.text = account.preferences.dietaryPreferences.join(', ');
          _allergiesController.text = account.preferences.allergies.join(', ');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("Name: ${account.profile.displayName}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Email: ${account.profile.email}"),
                Text("Health Score: ${account.healthInsight.healthScore}"),
                SizedBox(height: 20),
                TextField(
                  controller: _dietaryController,
                  decoration: InputDecoration(labelText: "Dietary Preferences (comma-separated)"),
                ),
                TextField(
                  controller: _allergiesController,
                  decoration: InputDecoration(labelText: "Allergies (comma-separated)"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text("Update Preferences"),
                  onPressed: () async {
                    final dietary = _dietaryController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final allergies = _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                    final success = await provider.updateUserPreferences(dietary, allergies);
                    final snackBar = SnackBar(content: Text(success ? "Updated!" : "Failed to update"));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _dietaryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}
