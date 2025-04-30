import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

//! Example, not really like this

//? To update preference
// Initially, in the user creation, every field is empty,
// So this is where you update the preference in the onboarding section

// TODO: Try utilizing the screen and then see the Firebase console (Firestore Database)
// TODO: side by side. And you will see it update in real time after saving it.

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  List<String> dietaryOptions = ['Vegetarian', 'Vegan', 'Gluten-Free']; 
  List<String> allergyOptions = ['Peanuts', 'Dairy', 'Shellfish'];

  List<String> selectedDietary = [];
  List<String> selectedAllergies = [];

  void updatePreferences() async {
    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('updateUserPreferences');
      final result = await callable.call({
        'dietaryPreferences': selectedDietary,
        'allergies': selectedAllergies,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Preferences updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Preferences")),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text("Dietary Preferences", style: TextStyle(fontSize: 18)),
            ...dietaryOptions.map((option) => CheckboxListTile(
                  title: Text(option),
                  value: selectedDietary.contains(option),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedDietary.add(option);
                      } else {
                        selectedDietary.remove(option);
                      }
                    });
                  },
                )),
            SizedBox(height: 20),
            Text("Allergies", style: TextStyle(fontSize: 18)),
            ...allergyOptions.map((option) => CheckboxListTile(
                  title: Text(option),
                  value: selectedAllergies.contains(option),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedAllergies.add(option);
                      } else {
                        selectedAllergies.remove(option);
                      }
                    });
                  },
                )),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updatePreferences,
              child: Text("Save Preferences"),
            ),
          ],
        ));
  }
}
