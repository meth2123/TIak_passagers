import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';


class Driver {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? motoModel;
  final String? plateNumber;
  final double? rating;
  final int? totalTrips;
  final DriverStatus status;
  final bool? verified;
  final LatLng? location;
  final double? heading;
  final double? speed;
  final bool? isAvailable;
  final DateTime? updatedAt;

  const Driver({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.motoModel,
    this.plateNumber,
    this.rating,
    this.totalTrips,
    required this.status,
    this.verified,
    this.location,
    this.heading,
    this.speed,
    this.isAvailable,
    this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      motoModel: json['motoModel'] as String?,
      plateNumber: json['plateNumber'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: json['totalTrips'] as int?,
      status: DriverStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DriverStatus.pending,
      ),
      verified: json['verified'] as bool?,
      location: json['location'] != null
          ? LatLng(
              (json['location']['lat'] as num).toDouble(),
              (json['location']['lng'] as num).toDouble(),
            )
          : null,
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'motoModel': motoModel,
      'plateNumber': plateNumber,
      'rating': rating,
      'totalTrips': totalTrips,
      'status': status.name,
      'verified': verified,
      'location': location != null
          ? {'lat': location!.latitude, 'lng': location!.longitude}
          : null,
      'heading': heading,
      'speed': speed,
      'isAvailable': isAvailable,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum DriverStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('suspended_24h')
  suspended24h,
  @JsonValue('suspended_review')
  suspendedReview,
  @JsonValue('blocked')
  blocked,
}
