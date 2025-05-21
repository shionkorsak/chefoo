import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'main_screen.dart';

abstract class MainController extends State<MainScreen> {
  late PageController carouselController;
  Timer? _inactivityTimer;
  int _carouselPage = 2;
  int shakeTarget = 0;

  bool isGpsEnabled = true;

  int get carouselPage => _carouselPage;
  set carouselPage(int value) => _carouselPage = value;

  bool get shouldShowGpsWarning => !isGpsEnabled;

  @override
  void initState() {
    super.initState();
    carouselController = PageController(
      initialPage: 2,
      viewportFraction: 0.6,
    );

    carouselController.addListener(() {
      final current = carouselController.page?.round();
      if (current != null && current != _carouselPage) {
        _carouselPage = current;
      }
    });

    checkGpsStatus();
    _startInactivityTimer();
  }

  Future<void> checkGpsStatus() async {
    final location = Location();
    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
    }
    if (mounted) {
      setState(() {
        isGpsEnabled = enabled;
      });
    }
  }

  void toggleGps() {
    setState(() {
      isGpsEnabled = !isGpsEnabled;
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        shakeTarget++;
      });
      _goToNextPage();
    });
  }

  void resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _goToNextPage() {
    if (!mounted) return;
    final nextPage = (_carouselPage + 1) % 5; // 5 cards assumed
    carouselController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _carouselPage = nextPage;
    _startInactivityTimer(); // restart the loop
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    carouselController.dispose();
    super.dispose();
  }
}