import 'package:flutter/material.dart';

class RatingController extends ChangeNotifier {
  List<Map<String, TextEditingController>> entries = [
    {
      'meal': TextEditingController(),
      'comment': TextEditingController(),
    }
  ];

  void addEntry() {
    entries.add({
      'meal': TextEditingController(),
      'comment': TextEditingController(),
    });
    notifyListeners();
  }

  void removeEntry(int index) {
    if (entries.length > 1) {
      entries[index]['meal']?.dispose();
      entries[index]['comment']?.dispose();
      entries.removeAt(index);
      notifyListeners();
    }
  }

  void disposeAll() {
    for (var entry in entries) {
      entry['meal']?.dispose();
      entry['comment']?.dispose();
    }
  }
}