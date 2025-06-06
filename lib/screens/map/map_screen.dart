import 'dart:math' as math;
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/restaurant_detail.dart';
import 'package:chefoo/screens/map/map_controller.dart';
import 'package:chefoo/utils/place_utils.dart';
import 'package:chefoo/widgets/tags/unclickable_tag.dart';

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
  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size / 2),
          /*boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // More subtle shadow
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],*/
        ),
        child: Center(
          child: Icon(
            icon,
            color: AppColors.primary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  Widget buildRestaurantCard() {
    if (selectedPlace == null) {
      return const SizedBox.shrink();
    }
    
    final pictureUrl = selectedEnrichedPlace!.pictureUrls.isNotEmpty 
      ? selectedPlace!.pictureUrls.first 
      : null;
    
    final _banner = PictureCategoryAssets();
    final headerImageUrl = _banner.pictureCategoryAssets[selectedEnrichedPlace!.pictureCategory] ?? pictureUrl;
      
    final crowdednessStatus = PlaceUtils.getCrowdednessStatus(selectedPlace!);
    
    String? todayOpeningHours;
    if (selectedPlace!.openingHours != null && selectedPlace!.openingHours!.isNotEmpty) {
      final now = DateTime.now();
      final currentWeekdayIndex = now.weekday == 7 ? 6 : now.weekday - 1;
      
      if (currentWeekdayIndex < selectedPlace!.openingHours!.length) {
        final fullHours = selectedPlace!.openingHours![currentWeekdayIndex];
        final parts = fullHours.split(': ');
        if (parts.length > 1) {
          todayOpeningHours = "Opening hours: ${parts[1]}";
        }
      }
    }
      
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(place: selectedPlace!),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 110, left: 24, right: 24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Container(
                    height: 120,
                    width: 120,
                    child: ClipRRect(
                      borderRadius: kRadius10,
                      child: Image.network(
                        headerImageUrl ?? 'https://maps.googleapis.com/maps/api/place/photo'
                        '?maxwidth=400'
                        '&photo_reference=${selectedEnrichedPlace!.pictureUrls.first}'
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
                          text: selectedEnrichedPlace!.name,
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
                      
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: List.generate(5, (index) {
                            final difference = selectedEnrichedPlace!.rating - index;
                            
                            IconData icon;
                            if (difference >= 1) {
                              icon = Icons.star;
                            } else if (difference >= 0.5) {
                              icon = Icons.star_half;
                            } else {
                              icon = Icons.star_border;
                            }
                            
                            return Icon(
                              icon,
                              size: 16,
                              color: AppColors.primary,
                            );
                          }),
                        ),
                      ),
                      
                      if (selectedEnrichedPlace!.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedEnrichedPlace!.tags.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return TagChip(
                                  label: selectedEnrichedPlace!.tags[index]
                                );
                              },
                            ),
                          ),
                        ),
                      
                      if (isLoadingPlaceDetails)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading hours...',
                                style: AppTextStyles.detail,
                              ),
                            ],
                          ),
                        )
                      else if (selectedPlace!.openingHours != null && selectedPlace!.openingHours!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Builder(
                            builder: (context) {
                              try {
                                final now = DateTime.now();
                                final dayIndex = now.weekday % 7;
                                final weekdayTexts = selectedPlace!.openingHours!;
                                
                                if (weekdayTexts.isEmpty || weekdayTexts.length <= dayIndex) {
                                  return Text('Hours not available', style: AppTextStyles.detail);
                                }
                                
                                final fullHours = weekdayTexts[dayIndex];
                                final parts = fullHours.split(': ');
                                
                                if (parts.length > 1) {
                                  final hoursText = parts[1].trim();
                                  
                                  if (hoursText.toLowerCase() == 'closed') {
                                    return Text('Today: Closed', style: AppTextStyles.detail);
                                  }
                                  
                                  return Text(
                                    '$hoursText',
                                    style: AppTextStyles.detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                return Text('Hours not available', style: AppTextStyles.detail);
                              } catch (e) {
                                print('Error formatting opening hours: $e');
                                return Text('Hours not available', style: AppTextStyles.detail);
                              }
                            },
                          ),
                        ),
                      
                      if (crowdednessStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getCrowdednessColor(crowdednessStatus),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getCrowdednessText(crowdednessStatus),
                                style: AppTextStyles.detail,
                              ),
                            ],
                          ),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          selectedPlace!.walkingDistance >= 1.0
                              ? '${selectedPlace!.walkingDistance.toStringAsFixed(1)}km'
                              : '${(selectedPlace!.walkingDistance * 1000).round()}m',
                          style: AppTextStyles.detail,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavigationButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: navigateToPreviousPlace,
                      size: 28,
                    ),
                    
                    SizedBox(width: 4),
                    
                    _buildNavigationButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: navigateToNextPlace,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCrowdednessColor(String status) {
    switch (status) {
      case "empty":
        return Colors.green;
      case "normal":
        return Colors.orange;
      case "crowded":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCrowdednessText(String status) {
    switch (status) {
      case "empty":
        return "Not busy";
      case "normal":
        return "Moderately busy";
      case "crowded":
        return "Very busy now";
      default:
        return "nope";
    }
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SECTION 9.1: MAP
          GoogleMap(
            initialCameraPosition: getInitialCameraPosition(),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
              print("Map controller created");
            
              createMarkersWithDestination();
              forceDrawRoute();
              
              if (hasActiveRoute) {
                Future.delayed(Duration(milliseconds: 300), () {
                  centerOnRoute();
                });
              }
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
                        17.0
                      ),
                    );
                  }
                }
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.only(bottom: 0),
            minMaxZoomPreference: MinMaxZoomPreference(minZoom, maxZoom),
          ),
          
          Positioned(
            right: 16,
              bottom: showPlaceCard ? 260 : 110,
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
    );
  }
}