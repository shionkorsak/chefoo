import 'dart:math' as math;
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:chefoo/screens/map/map_controller.dart';

class MapScreen extends StatefulWidget {
  final List<Place> places;
  final LatLng? destination;
  final String? destinationName;

  const MapScreen({
    Key? key,
    required this.places,
    this.destination,
    this.destinationName,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends MapController {
  // SECTION 8: UI COMPONENTS
  Widget buildRestaurantCard() {
    if (selectedPlace == null) {
      return const SizedBox.shrink();
    }
    
    final pictureUrl = selectedPlace!.pictureUrls.isNotEmpty 
      ? selectedPlace!.pictureUrls.first 
      : null;
      
    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      padding: kPadd10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: kRadius15,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pictureUrl != null)
            Container(
              height: 120,
              width: 120,
              child: ClipRRect(
                borderRadius: kRadius10,
                child: Image.network(
                  'https://maps.googleapis.com/maps/api/place/photo'
                  '?maxwidth=400'
                  '&photo_reference=${pictureUrl}'
                  '&key=${MapsConstants.mapsKey}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
            
          SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: Marquee(
                    text: selectedPlace!.name,
                    style: AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
                    scrollAxis: Axis.horizontal,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: Duration(seconds: 1),
                    startPadding: 10.0,
                    accelerationDuration: Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  ),
                ),
                  
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: AppColors.primary,
                        ),
                        Text(
                          selectedPlace!.rating.toString(),
                          style: AppTextStyles.detail.copyWith(height: 1),
                        )
                      ],
                    ),
                    Text(
                      selectedPlace!.tags.isNotEmpty
                          ? selectedPlace!.tags.first
                          : 'No tags available',
                      style: AppTextStyles.detail,
                    ),
                  ],
                ),
                
                Text(
                  '${selectedPlace!.walkingDistance.toStringAsFixed(1)}km',
                  style: AppTextStyles.detail,
                ),
                
                SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (selectedPlace!.phone != null)
                      PhoneButton(phoneNumber: selectedPlace!.phone!),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailScreen(place: selectedPlace!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 9: MAIN BUILD METHOD
  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final currentPosition = locationService.currentPosition;

    if (currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // SECTION 9.1: MAP
            GoogleMap(
              initialCameraPosition: getInitialCameraPosition(),
              markers: markers,
              polylines: polylines, // Make sure this is here
              onMapCreated: (controller) {
                mapController = controller;
                print("Map controller created");
                
                // Use a longer delay and explicitly draw routes ONCE
                Future.delayed(Duration(milliseconds: 1200), () {
                  // First add markers
                  createMarkersWithDestination();
                  
                  // Then explicitly force route drawing - ONLY HERE, not in controller again
                  forceDrawRoute();
                });
              },
              onTap: (LatLng position) {
                final wasShowingCard = showPlaceCard;
                
                setState(() {
                  selectedPlace = null;
                  selectedIndex = -1;
                  showPlaceCard = false;
                  createMarkersWithDestination();
                });

                if (wasShowingCard) {
                  if (hasActiveRoute) {
                    centerOnRoute();
                  } else {
                    final locationService = Provider.of<LocationService>(context, listen: false);
                    final currentPosition = locationService.currentPosition;
                    
                    if (currentPosition != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(currentPosition.latitude, currentPosition.longitude),
                          15.0
                        ),
                      );
                    }
                  }
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false, // Disable default zoom controls
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              compassEnabled: false,
              minMaxZoomPreference: MinMaxZoomPreference(minZoom, maxZoom),
            ),
            
            Positioned(
              right: 16,
              bottom: showPlaceCard ? 220 : 16,  // Position above the restaurant card if shown
              child: Column(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed: () {
                        mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, color: AppColors.primary),
                      onPressed: () {
                        mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // SECTION 9.2: RESTAURANT CARD
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: showPlaceCard ? buildRestaurantCard() : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}