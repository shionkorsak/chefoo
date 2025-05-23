import 'dart:async';
import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:chefoo/models/api_response.dart';
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

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _eventLocation;
  String get eventLocation => _eventLocation ?? "";

  @override
  void initState() {
    super.initState();

    _loadCalendarData();
    _initializeLocation();

    carouselController = PageController(
      initialPage: 0,
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

  Future<void> _initializeLocation() async {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    if(restaurantProvider.places.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      // return;
    }

    setState(() {
      _isLoading = true;
    });

    final locationService = 
      Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();

    final position = locationService.currentPosition;
    if(position != null) {
      await _fetchandRecommend(position);
    }
  }

  Future<void> _fetchandRecommend(Position position) async {
    final placeService = 
      Provider.of<PlaceService>(context, listen: false);
    final restaurantProvider = 
      Provider.of<RestaurantProvider>(context, listen: false);

    final service = AIRecommendationService(
      placeService: placeService, 
      restaurantProvider: restaurantProvider
    );

    try {
      await service.fetchAndRecommendNearbyPlaces(position, context);
    } catch (e) {
      log('Error fetching recommendations: $e');
    } finally {
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = 
      Provider.of<LocationService>(context);

    if(locationService.locationChangedSignificantly) {
      log('Location changed significantly, fetching new places');

      final position = locationService.currentPosition;
      if(position != null) {
        setState(() {
          _isLoading = true;
        });
        _fetchandRecommend(position);
      } else {
        log('position is null');
      }

      locationService.resetLocationChangedFlag();
    }
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
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final itemCount = restaurantProvider.places.length;
    if (itemCount == 0) return; // avoid division by zero

    final nextPage = (_carouselPage + 1) % itemCount;

    carouselController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _carouselPage = nextPage;
    _startInactivityTimer(); // restart the loop
  }

  Future<void> _loadCalendarData() async {
    try {
      print('Loading calendar data directly');
      
      final calendarService = CalendarService();
      
      setState(() {
        _isLoading = true;
      });
      
      final response = await calendarService.getNextEvent(forceRefresh: true);
      
      print('Calendar API response: ${response.success}, message: ${response.message}');
      
      if (response.success && response.data != null) {
        final event = response.data!;
        print('Event title: ${event.title}');
        print('Event location: ${event.location}');
        
        if (event.location != null && event.location.isNotEmpty) {
          final fullLocation = event.location;
          setState(() {
            _eventLocation = fullLocation.contains(',') 
                ? fullLocation.substring(0, fullLocation.indexOf(','))
                : fullLocation;
          });
          print('Event location set to: $_eventLocation');
        } else {
          print('Event has no location data');
          setState(() {
            _eventLocation = null;
          });
        }
      } else {
        print('No calendar event data available');
        setState(() {
          _eventLocation = null;
        });
      }
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() {
        _eventLocation = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    carouselController.dispose();
    super.dispose();
  }
}