import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _shouldRedirectToMain = false;

  AppStateProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  void markNavigationToMaps() {
    print('[APPSTATE]');
    _shouldRedirectToMain = true;
  }

  bool consumeRedirectFlag() {
    if (_shouldRedirectToMain) {
      _shouldRedirectToMain = false;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldRedirectToMain) {
      notifyListeners();
    }
  }
}
