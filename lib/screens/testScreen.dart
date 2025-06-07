import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/favorites/favorites_screen.dart';
import 'package:chefoo/screens/map_view.dart';
import 'package:chefoo/widgets/cards/restaurant_card_list_horizontal.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../providers/restaurant.dart';
import '../commons.dart';

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Nearby Restaurants',
      child: RestaurantListContainer(),
    );
  }
}

class RestaurantListContainer extends StatefulWidget {
  @override
  _RestaurantListContainerState createState() =>
      _RestaurantListContainerState();
}

class _RestaurantListContainerState extends State<RestaurantListContainer> {
  bool _isLoading = true;
  static const double _minDistanceToRefresh = 500.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final locationService =
        Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();

    if (mounted) {
      final position = locationService.currentPosition;
      if (position != null) {
        await _fetchNearbyPlaces(position);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locationService = Provider.of<LocationService>(context);

    if (locationService.locationChangedSignificantly) {
      print("Location changed significantly, fetching new places");

      final position = locationService.currentPosition;
      if (position != null) {
        _fetchNearbyPlaces(position);
      }

      locationService.resetLocationChangedFlag();
    }
  }

  Future<void> _fetchNearbyPlaces(Position position) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching places for location: ${position.latitude}, ${position.longitude}');

      final placeService = Provider.of<PlaceService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

      final cacheKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_1000';
      print('Using cache key: $cacheKey for nearby places');
      
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey,
      );

      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');
        
        final placesList = await placeService.exportCachedPlacesAsList(context);

        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('mainPick');
        final aiResponse = await callable.call({'data': placesList});
        final List<dynamic> recommendations = aiResponse.data['result'];
        final List<Place> allCachedPlaces = placeService.cachedPlaces.values.expand((list) => list).toList();

        final Map<String, List<Place>> newCache = {};
        
        for(var rec in recommendations) {
            final String recId = rec['id'];
            final List<String> recTags = List<String>.from(rec['tags']);

            Place? match;
            try {
                match = allCachedPlaces.firstWhere((p) => p.id == recId);
            } catch (_) {
                match = null;
            }

            if(match != null) {
                final updatedPlace = match.copyWith(tags: recTags);
                newCache.putIfAbsent('recommended', () => []).add(updatedPlace);
            }
        }
        restaurantProvider.setPlaces(newCache['recommended'] ?? []);
        
        if (response.message?.contains('cache') == true) {
          print('Used cache with ${response.data!.length} places');
        }
      } else {
        print('Failed to load places: ${response.message}');
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationService, RestaurantProvider>(
      builder: (context, locationService, restaurantProvider, _) {
        return Scaffold(
          // body: RestaurantList(
          //   places: restaurantProvider.places,
          //   isLoading: _isLoading,
          // ),
          body: RestaurantCardListHorizontal(
              without: false, places: restaurantProvider.places, isLoading: _isLoading),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'favorites',
                child: const Icon(Icons.favorite),
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritesScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'mapView',
                child: const Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapViewScreen(
                        places: restaurantProvider.places,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
