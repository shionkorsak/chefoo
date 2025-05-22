import 'package:chefoo/commons.dart';

class GetStartedProvider extends ChangeNotifier {
  int _state = 0;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _otherDietaryController = TextEditingController();
  bool _showFinalScreenContent = false;
  bool _nameError = false;
  List<String> _selectedTags = [];

  List<String> get selectedTags => _selectedTags;
  TextEditingController get allergiesController => _allergiesController;
  TextEditingController get otherDietaryController => _otherDietaryController;
  int get state => _state;
  bool get showFinalScreenContent => _showFinalScreenContent;
  bool get nameError => _nameError;

  void setState(int newState) {
    _state = newState;
    print("Onboarding state: $_state");
    notifyListeners();
  }

  void setShowFinalScreenContent(bool value) {
    _showFinalScreenContent = value;
    notifyListeners();
  }

  void setNameError(bool value) {
    _nameError = value;
    notifyListeners();
  }
  void setSelectedTags (List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  void reset() {
    _state = 0;
    _showFinalScreenContent = false;
    nameController.clear();
    _otherDietaryController.clear();;
    _nameError = false;
    _selectedTags = [];
    _allergiesController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    _allergiesController.dispose();
    _otherDietaryController.dispose();
    super.dispose();
  }
}