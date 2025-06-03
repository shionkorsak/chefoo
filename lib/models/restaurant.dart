// ignore_for_file: lines_longer_than_80_chars

// ignore_for_file: lines_longer_than_80_chars

import 'dart:collection';

class Place {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double distance;
  List<String> tags;
  String? phone;
  List<String>? openingHours;
  List<Review> reviews;
  final List<String> pictureUrls;
  final double lat;
  final double lng;
  final bool? isOpenNow;
  List<Map<String, dynamic>>? _popularTimes;
  bool _popularTimesLoaded = false;
  double walkingDistance;
  bool _detailsLoaded = false;
  final String pictureCategory;

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
    List<Map<String, dynamic>>? popularTimes,
    this.walkingDistance = 0.0,
    required this.pictureCategory
  }) : _popularTimes = popularTimes;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: json['rating'] as double,
      address: json['address'] as String,
      distance: json['distance'] as double,
      tags: List<String>.from(json['tags'] ?? []),
      phone: json['phone'] as String?,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      isOpenNow: json['isOpenNow'] as bool?,
      pictureUrls: List<String>.from(json['pictureUrls'] ?? []),
      reviews: [],
      openingHours: null,
      walkingDistance: json['walkingDistance'] as double? ?? 0.0,
      pictureCategory: ''
    );
  }

  factory Place.fromPlaceDetails(Map<String, dynamic> details) {
    final photoRefs = <String>{};
    final photos = (details['photos'] ?? []) as List;
    for (var photo in photos) {
      if (photo['photo_reference'] != null) {
        photoRefs.add(photo['photo_reference'] as String);
      }
    }

    final reviews = (details['reviews'] as List?)?.map((r) {
      String? photoRef;
      try {
        if ((r['photos'] as List?)?.isNotEmpty ?? false) {
          photoRef = r['photos'][0]['photo_reference'];
        }
      } catch (_) {}

      return Review(
        authorName: r['author_name'] ?? 'Anonymous',
        rating: (r['rating'] ?? 0).toDouble(),
        text: r['text'] ?? '',
        time: r['time']?.toString(),
        photoReference: photoRef,
      );
    }).toList() ?? [];

    return Place(
      id: details['place_id'] ?? '',
      name: details['name'] ?? 'Unnamed',
      rating: (details['rating'] ?? 0).toDouble(),
      address: details['formatted_address'] ?? '',
      phone: details['formatted_phone_number'] ?? '',
      lat: details['geometry']?['location']?['lat']?.toDouble() ?? 0.0,
      lng: details['geometry']?['location']?['lng']?.toDouble() ?? 0.0,
      isOpenNow: details['opening_hours']?['open_now'] ?? false,
      openingHours: (details['opening_hours']?['weekday_text'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      reviews: reviews,
      pictureUrls: photoRefs.toList(),
      tags: List<String>.from(details['tags'] ?? []),
      distance: 0.0,
      walkingDistance: (details['walking_distance'] ?? 0.0).toDouble(),
      popularTimes: null,
      pictureCategory: details['pictureCategory'] ?? ''
    );
  }


  factory Place.fromGooglePlace(Map<String, dynamic> place, Map<String, dynamic> details) {
    final List<String> allTypes = [
      ...List<String>.from(place['types'] ?? []),
      ...List<String>.from(details['types'] ?? []),
    ].toSet().toList();

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

    final List<String> types = [];
    if (place['types'] != null) {
      types.addAll(List<String>.from(place['types']));
    }

    return Place(
      id: place['place_id'] as String? ?? '',
      name: place['name'] as String? ?? '',
      rating: (place['rating'] ?? 0.0).toDouble(),
      address: place['vicinity'] as String? ?? '',
      distance: 0.0,
      tags: [],
      phone: details['formatted_phone_number'] as String? ?? '',
      openingHours: details['opening_hours']?['weekday_text']?.cast<String>(),
      reviews: reviews,
      pictureUrls: photoRefs.toList(),
      lat: place['geometry']['location']['lat'] as double,
      lng: place['geometry']['location']['lng'] as double,
      isOpenNow: details['opening_hours']?['open_now'] as bool?,
      popularTimes: popularTimesData,
      walkingDistance: 0.0, 
      pictureCategory: ''
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
      'lat': lat,
      'lng': lng,
      'isOpenNow': isOpenNow,
      'pictureUrls': pictureUrls,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    double? rating,
    String? address,
    double? distance,
    List<String>? tags,
    String? phone,
    List<String>? openingHours,
    List<Review>? reviews,
    List<String>? pictureUrls,
    double? lat,
    double? lng,
    bool? isOpenNow,
    List<Map<String, dynamic>>? popularTimes,
    bool? popularTimesLoaded,
    double? walkingDistance,
    bool? detailsLoaded,
    String? pictureCategory
  }) {
    final updated = Place(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      tags: tags ?? List.from(this.tags),
      phone: phone ?? this.phone,
      openingHours: openingHours ?? this.openingHours,
      reviews: reviews ?? List.from(this.reviews),
      pictureUrls: pictureUrls ?? List.from(this.pictureUrls),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      popularTimes: popularTimes ?? _popularTimes,
      walkingDistance: walkingDistance ?? this.walkingDistance,
      pictureCategory: pictureCategory ?? ''
   );

  if (popularTimesLoaded ?? _popularTimesLoaded) {
    updated._popularTimesLoaded = true;
  }

  if (detailsLoaded ?? _detailsLoaded) {
    updated._detailsLoaded = true;
  }

  return updated;
}


  List<Map<String, dynamic>>? get popularTimes => _popularTimes;

  bool get popularTimesLoaded => _popularTimesLoaded;

  bool get detailsLoaded => _detailsLoaded;

  void setPopularTimes(List<Map<String, dynamic>>? data) {
    _popularTimes = data;
    _popularTimesLoaded = true;
  }

  void markDetailsLoaded() {
    _detailsLoaded = true;
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
