import 'dart:collection';

class Place {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double distance;
  final List<String> tags;
  final String? phone;
  final List<String>? openingHours;
  final List<Review> reviews;
  final List<String> pictureUrls;
  final double lat;
  final double lng;
  final bool? isOpenNow;
  List<Map<String, dynamic>>? popularTimes;
  double walkingDistance; // Add this field

  Place({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.distance,
    required this.tags,
    this.phone,
    this.openingHours,
    required this.reviews,
    required this.pictureUrls,
    required this.lat,
    required this.lng,
    this.isOpenNow,
    this.popularTimes,
    this.walkingDistance = 0.0, // Add this parameter
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      address: json['address'] as String,
      distance: (json['distance'] as num).toDouble(),
      tags: (json['tags'] as List).cast<String>(),
      phone: json['phone'] as String?,
      openingHours: (json['opening_hours'] as List?)?.cast<String>(),
      reviews: (json['reviews'] as List)
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList(),
      pictureUrls: (json['pictures'] as List).cast<String>(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isOpenNow: json['is_open_now'] as bool?,
      popularTimes: (json['popular_times'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      walkingDistance: (json['walking_distance'] as num?)?.toDouble() ?? 0.0, // Add this field
    );
  }

  factory Place.fromGooglePlace(Map<String, dynamic> place, Map<String, dynamic> details) {
    final Set<String> photoRefs = <String>{};
    
    if (place['photos'] != null) {
      final photos = place['photos'] as List;
      for (var i = 1; i < photos.length; i++) {
        if (photos[i]['photo_reference'] != null) {
          photoRefs.add(photos[i]['photo_reference'] as String);
        }
      }
    }

    if (details['photos'] != null) {
      final photos = details['photos'] as List;
      for (var photo in photos) {
        if (photo['photo_reference'] != null) {
          photoRefs.add(photo['photo_reference'] as String);
        }
      }
    }

    print('Found ${photoRefs.length} unique photos for ${place['name']}');

    final reviews = (details['reviews'] as List?)?.map((r) {
      String? photoRef;
      
      if (r['photos'] != null && 
          (r['photos'] as List).isNotEmpty && 
          r['photos'][0]['photo_reference'] != null) {
        photoRef = r['photos'][0]['photo_reference'] as String;
      }

      return Review(
        authorName: r['author_name'] as String,
        rating: (r['rating'] as num).toDouble(),
        text: r['text'] as String,
        time: r['time']?.toString(),
        photoReference: photoRef,
      );
    }).toList() ?? [];

    // Parse popular times data
    List<Map<String, dynamic>>? popularTimesData;
    if (details['populartimes'] != null) {
      try {
        popularTimesData = (details['populartimes'] as List).map((day) {
          return {
            'name': day['name'],
            'data': List<int>.from(day['data']),
          };
        }).toList();
        print('Parsed popular times for ${place['name']}: ${popularTimesData.length} days');
      } catch (e) {
        print('Error parsing popular times: $e');
      }
    }

    return Place(
      id: place['place_id'] as String,
      name: place['name'] as String,
      rating: (place['rating'] ?? 0.0).toDouble(),
      address: place['vicinity'] as String,
      distance: 0.0,
      tags: [],
      phone: details['formatted_phone_number'] as String?,
      openingHours: details['opening_hours']?['weekday_text']?.cast<String>(),
      reviews: reviews,
      pictureUrls: photoRefs.toList(),
      lat: place['geometry']['location']['lat'] as double,
      lng: place['geometry']['location']['lng'] as double,
      isOpenNow: details['opening_hours']?['open_now'] as bool?,
      popularTimes: popularTimesData,
      walkingDistance: 0.0, // Will be updated after creation
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'address': address,
      'distance': distance,
      'tags': tags,
      'phone': phone,
      'opening_hours': openingHours,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'pictures': pictureUrls,
      'lat': lat,
      'lng': lng,
      'is_open_now': isOpenNow,
      'popular_times': popularTimes,
      'walking_distance': walkingDistance, // Add this field
    };
  }

  void updatePopularTimes(List<Map<String, dynamic>> times) {
    popularTimes = times;
  }
}

class Review {
  final String authorName;
  final double rating;
  final String text;
  final String? time;
  final String? photoReference;

  String get formattedTime {
    if (time == null) return '';
    final timestamp = int.tryParse(time!);
    if (timestamp == null) return '';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months > 1 ? '$months months ago' : 'a month ago';
    } else if (difference.inDays > 0) {
      return difference.inDays > 1 ? '${difference.inDays} days ago' : 'yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    this.time,
    this.photoReference,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String? photoRef;
    if (json['photos'] != null && 
        (json['photos'] as List).isNotEmpty && 
        json['photos'][0]['photo_reference'] != null) {
      photoRef = json['photos'][0]['photo_reference'] as String;
    }

    return Review(
      authorName: json['author_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      text: json['text'] as String,
      time: json['time']?.toString(),
      photoReference: photoRef,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'profile_photo_url': null,
      'rating': rating,
      'text': text,
      'time': time,
      'photo_reference': photoReference,
    };
  }
}
