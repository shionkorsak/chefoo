import 'dart:async';
import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/splash/splash.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:chefoo/providers/calendar_state.dart';
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

  bool _isAILoading = false;
  bool get isAILoading => _isAILoading;

  String eventLocation = '';
  String eventName = '';

  StreamSubscription<Position>? _locationSubscription;

  ValueKey<String> _locationKey = ValueKey('initial');
  ValueKey<String> get locationKey => _locationKey;

  @override
  void initState() {
    super.initState();

    carouselController = PageController(
      initialPage: 0,
      viewportFraction: 0.6,
    );

    aiInputController.addListener(() {
      final input = aiInputController.text.trim();

      if (input.isNotEmpty && input != _aiQuery && input != 'mock') {
        onAIQuerySubmitted(input);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService =
          Provider.of<LocationService>(context, listen: false);

      if (locationService.currentPosition != null) {
        print(
            '[MAIN CTRL] Initial position: ${locationService.currentPosition!.latitude}, ${locationService.currentPosition!.longitude}');
      }

      _locationSubscription =
          locationService.locationChangedStream.listen((position) {
        if (mounted) {
          print('[MAIN CTRL] Location changed, restarting app flow');
          handleSignificantLocationChange();
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

    final recommendedProvider = Provider.of<RecommendedProvider>(context);
    recommendedProvider.addListener(_setRecommendedPlace);

    final locationService = Provider.of<LocationService>(context);

    if (locationService.locationChangedSignificantly) {
      final position = locationService.currentPosition;
      if (position != null) {
        handleSignificantLocationChange();
      }
      locationService.resetLocationChangedFlag();
    }
  }

  Future<void> _setRecommendedPlace() async {
    final recommendedProvider =
        Provider.of<RecommendedProvider>(context, listen: false);

    if (mounted) {
      setState(() {
        _recommendedPlaces = recommendedProvider.recommended;
        _enrichedPlaces = recommendedProvider.enriched;
      });
    }
  }

  Future<void> _refreshRecommendedPlaces() async {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final recommendedProvider =
        Provider.of<RecommendedProvider>(context, listen: false);
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
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

    final newLocationKey = ValueKey(
        '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}');

    setState(() {
      _isLoading = true;
      _locationKey = newLocationKey;
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
        placeService.cleanupPlaceCache();

        print(
            '[MAIN-CTRL] Successfully fetched ${response.data!.length} places from API and cached.');

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

    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
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

      print(
          'Calendar API response: ${response.success}, message: ${response.message}');

      if (response.success && response.data != null) {
        final event = response.data!;
        print('Event title: ${event.title}');
        print('Event location: ${event.location}');

        if (event.location != null && event.location.isNotEmpty) {
          final fullLocation = event.location;
          setState(() {
            eventLocation = fullLocation.contains(',')
                ? fullLocation.substring(0, fullLocation.indexOf(','))
                : fullLocation;
            eventName = event.title ?? '';
          });
          print('Event location set to: $eventLocation');
        } else {
          print('Event has no location data');
          setState(() {
            eventLocation = '';
            eventName = '';
          });
        }
      } else {
        print('No calendar event data available');
        setState(() {
          eventLocation = '';
          eventName = '';
        });
      }
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() {
        eventLocation = '';
        eventName = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    Provider.of<RecommendedProvider>(context, listen: false)
        .removeListener(_setRecommendedPlace);
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

  void onAIQuerySubmitted(String query) async {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      setState(() {
        _aiQuery = '';
        _aiGeneratedResults.clear();
      });
      return;
    }

    setState(() {
      _aiQuery = query;
      _isAILoading = true;  // Use AI-specific loading state
      _aiGeneratedResults.clear();
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _aiGeneratedResults = [];
        _isLoading = false;
      });
      return;
    }

    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final placeService = Provider.of<PlaceService>(context, listen: false);
    final recommendedProvider =
        Provider.of<RecommendedProvider>(context, listen: false);
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);

    final recommendationService = RecommendationService(
      restaurantProvider: restaurantProvider,
      placeService: placeService,
    );

    try {
      final result =
          await recommendationService.fetchSingleRecommendationFromAIQuery(
        message: query,
        uid: uid,
        enrichedPlaces: recommendedProvider.enriched,
        favoritesProvider: favoritesProvider,
      );

      if (!mounted) return;

      setState(() {
        if (result != null) {
          _aiGeneratedResults.add(result);
        }
      });
    } catch (e) {
      print('[AI] Error during msgAI call: $e');
      setState(() {
        _aiGeneratedResults = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAILoading = false;  // Reset AI-specific loading state
        });
      }
    }
  }


  List<Place> get aiGeneratedResults => _aiGeneratedResults;
  String get aiQuery => _aiQuery;

  void handleSignificantLocationChange() {
    print('[MAIN CTRL] Handling significant location change');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      print('[MAIN CTRL] Showing location change dialog');

      bool restartInProgress = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('Location Changed',
              style: AppTextStyles.headline2, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                'Your location has changed significantly.\nReloading data, please wait a moment...',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      );

      Future.delayed(Duration(seconds: 3), () {
        print(
            '[MAIN CTRL] Dialog shown for 3 seconds, navigating to splash screen');

        if (!mounted) {
          print('[MAIN CTRL] Widget no longer mounted, cancelling navigation');
          return;
        }

        Navigator.of(context).pop();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SplashScreen(
              isReloading: true,
              onReloadComplete: () {
                print('[MAIN CTRL] Reload complete, returning to main screen');
                restartInProgress = false;
              },
            ),
          ),
          (route) => false,
        );
      });
    });
  }
}
