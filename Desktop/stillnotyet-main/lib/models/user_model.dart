import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final List<String> interests;
  final String location;
  // Add GeoPoint for location-based matching
  final GeoPoint? geoPoint;

  // Optional fields for enhanced matching
  final String gender;
  final String lookingFor;
  final int distance;
  final int ageRangeStart;
  final int ageRangeEnd;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.interests,
    required this.location,
    this.geoPoint,
    this.gender = '',
    this.lookingFor = '',
    this.distance = 50,
    this.ageRangeStart = 18,
    this.ageRangeEnd = 50,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 25,
      bio: json['bio'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      location: json['location'] ?? '',
      geoPoint: json['geoPoint'],
      gender: json['gender'] ?? '',
      lookingFor: json['lookingFor'] ?? '',
      distance: json['distance'] ?? 50,
      ageRangeStart: json['ageRangeStart'] ?? 18,
      ageRangeEnd: json['ageRangeEnd'] ?? 50,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Print the raw data for debugging
      print('Raw user data for ${doc.id}: $data');

      // Handle potentially missing fields
      return User(
        id: doc.id,
        name: data['name'] ?? 'Unknown',
        age: data['age'] ?? 25,
        bio: data['bio'] ?? '',
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        interests: List<String>.from(data['interests'] ?? []),
        location: data['location'] ?? 'Unknown',
        geoPoint: data['geoPoint'],
        gender: data['gender'] ?? '',
        lookingFor: data['lookingFor'] ?? '',
        distance: data['distance'] ?? 50,
        ageRangeStart: data['ageRangeStart'] ?? 18,
        ageRangeEnd: data['ageRangeEnd'] ?? 50,
      );
    } catch (e) {
      print('Error parsing user data for ${doc.id}: $e');
      // Return a default user in case of parsing error
      return User(
        id: doc.id,
        name: 'Error User',
        age: 0,
        bio: 'Error loading user data',
        imageUrls: [],
        interests: [],
        location: 'Unknown',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'imageUrls': imageUrls,
      'interests': interests,
      'location': location,
      'geoPoint': geoPoint,
      'gender': gender,
      'lookingFor': lookingFor,
      'distance': distance,
      'ageRangeStart': ageRangeStart,
      'ageRangeEnd': ageRangeEnd,
    };
  }

  User copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<String>? imageUrls,
    List<String>? interests,
    String? location,
    GeoPoint? geoPoint,
    String? gender,
    String? lookingFor,
    int? distance,
    int? ageRangeStart,
    int? ageRangeEnd,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      geoPoint: geoPoint ?? this.geoPoint,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      distance: distance ?? this.distance,
      ageRangeStart: ageRangeStart ?? this.ageRangeStart,
      ageRangeEnd: ageRangeEnd ?? this.ageRangeEnd,
    );
  }
}