import 'dart:async';
import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:chefoo/models/api_response.dart';
import 'package:chefoo/services/database/history_service.dart';
import 'package:chefoo/providers/main_screen.dart';
import 'main_screen.dart';

abstract class MainController extends State<MainScreen> {
  final TextEditingController aiInputController = TextEditingController();
  String _aiQuery = '';
  List<Place> _aiGeneratedResults = [];
  List<Place> _recommendedPlaces = [];
  List<Place> get recommendedPlaces => _recommendedPlaces;

  List<Place> _enrichedPlaces = [];
  List<Place> get enrichedPlaces => _enrichedPlaces;

  bool _showRatePopup = true;
  bool get showRatePopup => _showRatePopup;

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

  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    carouselController = PageController(
      initialPage: 0,
      viewportFraction: 0.6,
    );

    aiInputController.addListener(() {
      final input = aiInputController.text.trim();
      if (input.isNotEmpty && input != _aiQuery) {
        onAIQuerySubmitted(input);
      }
    });
    aiInputController.text = 'mock';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      
      _locationSubscription = locationService.locationChangedStream.listen((position) {
        if (mounted) {
          restaurantProvider.updateCurrentPlaces(
            position.latitude,
            position.longitude,
            1000.0
          );
          
          if (mounted) {
            print('[MAIN CTRL] Location changed, refreshing data');
            _refreshRecommendedPlaces();
          }
        }
      });
    });

    _loadCalendarData();
    checkGpsStatus();
    _startInactivityTimer();
    _setRecommendedPlace();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = 
      Provider.of<LocationService>(context);

    if(locationService.locationChangedSignificantly) {
      final position = locationService.currentPosition;
      if(position != null) {
        log('[MAIN CTRL] Location changed significantly, fetching new places');
        _refreshRecommendedPlaces();
      } else {
        log('position is null');
      }

      locationService.resetLocationChangedFlag();
    }
  }

  Future<void> _setRecommendedPlace() async {
    final recommendedProvider = Provider.of<RecommendedProvider>(context, listen: false);
    final recommended = recommendedProvider.recommended;

    if (mounted) {
      setState(() {
        _recommendedPlaces = recommended;
      });
    }
    final meals = await HistoryService().fetchMeals();
    final mainScreenProvider = Provider.of<MainScreenProvider>(context, listen: false);
    mainScreenProvider.setAllMeals(meals);
  }

  Future<void> _refreshRecommendedPlaces() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final recommendedProvider = Provider.of<RecommendedProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final placeService = Provider.of<PlaceService>(context, listen: false);
    final recommendationService = RecommendationService(
      restaurantProvider: restaurantProvider,
      placeService: placeService,
    );
    final uid = AuthService().getCurrentUserUID() ?? 'guest';
    final position = locationService.currentPosition;

    print('[MAIN-CTRL] Loading everything');
    if (position == null) {
      print('[MAIN-CTRL] Cannot load without position');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await recommendedProvider.cleanupOldEntries(uid);
      
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000,
        apiKey: MapsConstants.mapsKey,
        addToCache: true,
      );

      if (response.success && response.data != null) {
        print('[MAIN-CTRL] Successfully fetched ${response.data!.length} places from API and cached.');

        final result = await recommendationService.fetchRecommendedFromProvider(
          lat: position.latitude,
          lng: position.longitude,
        );

        await recommendedProvider.setRecommendations(
          recommended: result['recommended'] ?? [],
          enriched: result['enriched'] ?? [],
          uid: uid,
          position: position,
          radius: 1000.0,
        );
      }

      if (mounted) {
        setState(() {
          _recommendedPlaces = recommendedProvider.recommended;
          _enrichedPlaces = recommendedProvider.enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[MAIN-CTRL] Error refreshing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> checkGpsStatus() async {
    final location = Location();
    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
    }
    if (mounted) {
      setState(() => isGpsEnabled = enabled);
    }
  }

  void toggleGps() {
    setState(() => isGpsEnabled = !isGpsEnabled);
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => shakeTarget++);
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

    //final nextPage = (_carouselPage + 1) % itemCount;
    // Only try to animate if the controller is attached
    if (carouselController.hasClients) {
      final nextPage = (_carouselPage + 1) % itemCount;

      carouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _carouselPage = nextPage;
      _startInactivityTimer(); // restart the loop
    }
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
    aiInputController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  void dismissRatePopup() {
    setState(() {
      _showRatePopup = false;
    });
  }

  void onAIQuerySubmitted(String query) {
    setState(() {
      _aiQuery = query;
      _aiGeneratedResults = _getMockResults(); // always show 3 mock cards for visuals
    });
  }

  // TODO: Implement actual AI recommendation fetching logic using RecommendationService
  List<Place> _getMockResults() {
    return _recommendedPlaces.take(3).toList(); // Just mock using subset of recommendedPlaces
  }

  List<Place> get aiGeneratedResults => _aiGeneratedResults;
  String get aiQuery => _aiQuery;
}