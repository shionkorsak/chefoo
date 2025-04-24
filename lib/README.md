# Chefoo - Restaurant Finder App

## Setup Guide
See [Setup Instructions](SETUP.md) for installation steps.

## Available Services

### 1. Restaurant Data
```dart
import 'package:chefoo/commons.dart';

// Get restaurant provider
final provider = Provider.of<RestaurantProvider>(context);

// Access restaurant data
final restaurants = provider.places;
final selectedRestaurant = provider.selectedPlace;

// Update restaurants
provider.setPlaces(newPlaces);
provider.setSelectedPlace(place);
```

### 2. Location Services
```dart
import 'package:chefoo/commons.dart';

// Get location service
final location = Provider.of<LocationService>(context);

// Access location data
final currentPosition = location.currentPosition;
final isLoading = location.isLoading;

// Get distance to restaurant
final distance = location.getDistanceString(place.lat, place.lng);

// Update location
location.getCurrentLocation();
```

### 3. Maps Integration
```dart
import 'package:chefoo/commons.dart';

// Get maps service
final mapsService = Provider.of<PlaceService>(context);

// Fetch nearby restaurants
final response = await mapsService.getNearbyPlaces(
  lat: position.latitude,
  lng: position.longitude,
  radius: 1000.0,
  apiKey: MapsConstants.mapsKey,
);
```

### 4. Popular Times
```dart
// Use the PopularTimesChart widget
PopularTimesChart(
  popularTimes: place.popularTimes!,
  openingHours: place.openingHours,
)
```

## Models

### Place Model
```dart
Place place = Place(
  id: 'id',
  name: 'Restaurant Name',
  rating: 4.5,
  address: '123 Street',
  distance: 0.5,
  tags: ['restaurant', 'food'],
  lat: 0.0,
  lng: 0.0,
);

// Access properties
print(place.name);
print(place.rating);
print(place.isOpenNow);
print(place.walkingDistance);
```

### Review Model
```dart
Review review = Review(
  authorName: 'John Doe',
  rating: 4.0,
  text: 'Great place!',
  time: '1650000000',
);

// Get formatted time (e.g., "2 days ago")
print(review.formattedTime);
```

## Common Use Cases

### 1. Show Restaurant List
```dart
Consumer2<LocationService, RestaurantProvider>(
  builder: (context, locationService, restaurantProvider, _) {
    return RestaurantList(
      places: restaurantProvider.places,
      isLoading: false,
    );
  },
);
```

### 2. Show Restaurant Details
```dart
RestaurantCard(
  place: place,
)
```

### 3. Show Map View
```dart
MapViewScreen(
  places: restaurantProvider.places,
)
```

### 4. Show Photos
```dart
PhotoGrid(
  photoRefs: place.pictureUrls,
  placeName: place.name,
)
```

## UI Components Guide

### Restaurant Elements
Ready-to-use UI components for restaurant information:

```dart
import 'package:chefoo/commons.dart';

// Basic Info Components
RestaurantName(place.name)                              // Restaurant name with styling
RestaurantAddress(place.address)                        // Formatted address
RestaurantRating(rating: place.rating)                  // Star rating display
RestaurantDistance(distanceKm: place.walkingDistance)   // Walking distance with icon
OpenStatusBadge(isOpen: place.isOpenNow ?? false)      // Open/Closed status badge

// Action Components
PhoneButton(phoneNumber: place.phone!)                  // Call button with formatting
DirectionsButton(lat: place.lat, lng: place.lng)        // Google Maps directions
```

### Example Layouts

1. Basic Restaurant Header:
```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RestaurantName(place.name),
          RestaurantAddress(place.address),
        ],
      ),
    ),
    OpenStatusBadge(isOpen: place.isOpenNow ?? false),
  ],
)
```

2. Rating & Distance Bar:
```dart
Row(
  children: [
    RestaurantRating(rating: place.rating),
    const SizedBox(width: 8),
    RestaurantDistance(distanceKm: place.walkingDistance),
  ],
)
```

### Additional Widgets

#### Popular Times Chart
Shows restaurant busy hours:
```dart
PopularTimesChart(
  popularTimes: place.popularTimes!,
  openingHours: place.openingHours,
)
```

#### Photo Grid
Displays restaurant photos:
```dart
PhotoGrid(
  photoRefs: place.pictureUrls,
  placeName: place.name,
)
```

### Full Example

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: RestaurantName(place.name),
            ),
            OpenStatusBadge(isOpen: place.isOpenNow ?? false),
          ],
        ),
        const SizedBox(height: 8),
        
        // Address
        RestaurantAddress(place.address),
        const SizedBox(height: 8),
        
        // Rating & Distance
        Row(
          children: [
            RestaurantRating(rating: place.rating),
            const SizedBox(width: 8),
            RestaurantDistance(distanceKm: place.walkingDistance),
          ],
        ),
        const SizedBox(height: 16),
        
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (place.phone != null)
              PhoneButton(phoneNumber: place.phone!),
            DirectionsButton(lat: place.lat, lng: place.lng),
          ],
        ),
      ],
    ),
  ),
)
```

### Style Customization

Most components accept style parameters:
```dart
RestaurantName(
  place.name,
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
)
```

## Import All Components
Just import the commons file:
```dart
import 'package:chefoo/commons.dart';
```

This gives you access to all UI components and necessary providers.

## Error Handling

All API responses are wrapped in `ApiResponse<T>`:
```dart
final response = await mapsService.getNearbyPlaces(...);

if (response.success) {
  final places = response.data!;
  // Handle success
} else {
  final error = response.error;
  // Handle error
}
```