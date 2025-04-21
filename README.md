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
npm i
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

5. Install Flutter dependencies:
```bash
flutter pub get
```

6. Start the proxy server:
```bash
node proxy.js
```

7. In a new terminal, start the backend server:
```bash
node server.js
```

8. Run the Flutter app:
```bash
flutter run
```

## Component documentation
Feel free to edit anything you want. All the frontend-esque stuff I have is because I was testing to see if I was importing info correctly etc!

### Widgets

#### 1. BaseLayout
A wrapper widget that provides common functionality:
- App bar with title (you maybe should delete this?)
- Location service initialization
- Loading states
- Error handling

Usage:
```dart
BaseLayout(
  title: 'Screen Title',
  child: YourWidget(),
)
```

#### 2. RestaurantCard
Displays detailed information about a restaurant:
- Name, rating, and distance
- Opening hours
- Popular times chart
- Reviews
- Photos with grid view
- Phone number and directions buttons

Usage:
```dart
RestaurantCard(place: placeObject)
```

#### 3. PopularTimesChart
Shows restaurant busy times in a graph:
- Day-by-day view with navigation
- Hour-by-hour popularity data
- Interactive time selection

Usage:
```dart
PopularTimesChart(popularTimes: placeObject.popularTimes!)
```

#### 4. PhotoGrid
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

### Services

#### 1. LocationService
Handles location-related functionality:
- Get current location
- Calculate distances
- Location permissions
- Error handling

Usage:
```dart
final locationService = Provider.of<LocationService>(context);
final position = locationService.currentPosition;
```

#### 2. PopularTimesService
Fetches real-time popularity data:
- Get current popularity
- Day-by-day predictions
- Error handling

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

### Proxy Server (port 3000)
- `/nearbysearch` - Get nearby restaurants
- `/details` - Get restaurant details
- `/photo` - Get restaurant photos

### Backend Server (port 3001)
- `/api/populartimes/:placeId` - Get popularity data

## Important notes

1. State Management:
   - Location state is managed via Provider
   - Restaurant data is managed in RestaurantListContainer
   - Popular times use local state in their widget

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