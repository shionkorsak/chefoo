# chefoo

## How to set up

### Prerequisites
- Flutter
- Node.js (v14 or higher)
- Python
- Google Maps API key (find it in our notion)

### Installation steps

1. Clone the repo:
```bash
git clone https://github.com/shionkorsak/chefoo.git
cd chefoo
```

2. Install Node.js dependencies:
```zsh
npm init -y
```

3. Install Python dependencies (busyness info):
```zsh
pip3 install --upgrade git+https://github.com/m-wrzr/populartimes
```
or, if this doesn't work because you don't have Python3 installed:
```zsh
pip install --upgrade git+https://github.com/m-wrzr/populartimes
```

4. Create a `.env` file in the *ROOT* directory:
```env
GOOGLE_MAPS_API_KEY=key_here
```

you can find the key in our notion

5. Install Flutter dependencies:
```bash
flutter pub get
```

6. In a new terminal, start the backend server:
```bash
node server.js
```

7. Run the Flutter app:
```bash
flutter run
```

## Component documentation
Feel free to edit anything you want. All the frontend-esque stuff I have is because I was testing to see if I was importing info correctly etc!

!!! for anything you wanna import, just import commons because i put everything there (so far...)
```dart
import 'package:chefoo/widgets/popular_times_chart.dart';
```

### Widgets

#### 1. Popular Times Widget

Shows restaurant busy hours in a chart:
- Day-by-day view with navigation arrows
- Hour-by-hour popularity data
- Automatic adjustment to restaurant opening hours
- Shows "Closed" message on closed days

Basic usage:
```dart
import 'package:chefoo/widgets/popular_times_chart.dart';

PopularTimesChart(
  popularTimes: place.popularTimes!, 
  openingHours: place.openingHours,
)
```

The widget expects:
- `popularTimes`: List of daily popularity data
- `openingHours`: List of opening hours strings (optional)

Example usage:
```dart
if (place.popularTimes != null && place.popularTimes!.isNotEmpty) 
  PopularTimesChart(
    popularTimes: place.popularTimes!,
    openingHours: place.openingHours,
  ),
```

#### 2. PhotoGrid
Displays restaurant photos in a grid layout:
- Fullscreen view
- 2-column grid
- Loading states and error handling

Usage:
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

### Services

#### 1. LocationService
Handles location-related functionality:
- Get current location
- Calculate distances
- Location permissions

Usage:
```dart
final locationService = Provider.of<LocationService>(context);
final position = locationService.currentPosition;
```

#### 2. PopularTimesService
Fetches real-time popularity data:
- Get current popularity
- Day-by-day predictions

Usage:
```dart
final service = PopularTimesService();
final times = await service.getPopularTimes(placeId);
```

### Models

#### 1. Place
Restaurant data model containing:
- Basic info (name, address, rating)
- Opening hours
- Reviews
- Photos
- Popular times
- Location coordinates

Usage:
```dart
Place place = Place.fromJson(jsonData);
// or
Place place = Place.fromGooglePlace(placeData, detailsData);
```

## API Routes

### Backend Server (port 3001)
- `/api/populartimes/:placeId` - Get popularity data

## Troubleshooting

1. If images don't load:
   - Check if proxy server is running
   - Verify photo references are valid
   - Check console for error messages

2. If popular times don't show:
   - Ensure backend server is running
   - Check if place ID is valid
   - Verify Python dependencies are installed

3. If location doesn't update:
   - Check location permissions
   - Verify GPS is enabled
   - Try refreshing?
