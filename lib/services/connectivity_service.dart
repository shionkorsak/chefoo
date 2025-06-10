import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../screens/splash/no_inter.dart';
import 'package:chefoo/constants.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _hasInternet = true;

  bool get hasInternet => _hasInternet;

  void initialize(BuildContext context) async {
    final result = await _connectivity.checkConnectivity();
    _hasInternet = result != ConnectivityResult.none;

    if (!_hasInternet) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NoInternetScreen()),
        (route) => false,
      );
    }

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _hasInternet = result != ConnectivityResult.none;
      notifyListeners();

      if (!_hasInternet) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NoInternetScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _hasInternet = result != ConnectivityResult.none;
    notifyListeners();
    return _hasInternet;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
