import 'package:flutter/material.dart';

class GetStartedProvider extends ChangeNotifier {
  int _state = 0;
  final TextEditingController nameController = TextEditingController();

  int get state => _state;

  void setState(int newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}