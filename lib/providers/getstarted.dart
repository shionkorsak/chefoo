import 'package:chefoo/commons.dart';

class GetStartedProvider extends ChangeNotifier {
  int _state = 0;
  final TextEditingController nameController = TextEditingController();
  bool _showFinalScreenContent = false;
  bool _nameError = false;

  int get state => _state;
  bool get showFinalScreenContent => _showFinalScreenContent;
  bool get nameError => _nameError;

  void setState(int newState) {
    _state = newState;
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

  void reset() {
    _state = 0;
    _showFinalScreenContent = false;
    nameController.clear();
    _nameError = false;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}