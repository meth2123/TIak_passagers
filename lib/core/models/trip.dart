import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';


class Trip {
  final String id;
  final String passengerId;
  final String? driverId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String? pickupAddress;
  final String? dropoffAddress;
  final int? estimatedPriceFcfa;
  final int? actualPriceFcfa;
  final double? estimatedDistanceKm;
  final double? actualDistanceKm;
  final int? estimatedDurationMin;
  final int? actualDurationMin;
  final Map<String, dynamic>? pricingSnapshot;
  final TripStatus status;
  final PaymentMethod paymentMethod;
  final String? gpsLogBlobUrl;
  final String? cancellationReason;
  final TripCancellationBy? cancelledBy;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? driverArrivedAt;
  final DateTime? startedAt;
  final DateTime? driverConfirmedAt;
  final DateTime? passengerConfirmedAt;
  final DateTime? autoConfirmedAt;
  final DateTime? completedAt;
  final DateTime? disputedAt;

  const Trip({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupAddress,
    this.dropoffAddress,
    this.estimatedPriceFcfa,
    this.actualPriceFcfa,
    this.estimatedDistanceKm,
    this.actualDistanceKm,
    this.estimatedDurationMin,
    this.actualDurationMin,
    this.pricingSnapshot,
    required this.status,
    required this.paymentMethod,
    this.gpsLogBlobUrl,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.acceptedAt,
    this.driverArrivedAt,
    this.startedAt,
    this.driverConfirmedAt,
    this.passengerConfirmedAt,
    this.autoConfirmedAt,
    this.completedAt,
    this.disputedAt,
  });

  Trip copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    String? pickupAddress,
    String? dropoffAddress,
    int? estimatedPriceFcfa,
    int? actualPriceFcfa,
    double? estimatedDistanceKm,
    double? actualDistanceKm,
    int? estimatedDurationMin,
    int? actualDurationMin,
    Map<String, dynamic>? pricingSnapshot,
    TripStatus? status,
    PaymentMethod? paymentMethod,
    String? gpsLogBlobUrl,
    String? cancellationReason,
    TripCancellationBy? cancelledBy,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? driverArrivedAt,
    DateTime? startedAt,
    DateTime? driverConfirmedAt,
    DateTime? passengerConfirmedAt,
    DateTime? autoConfirmedAt,
    DateTime? completedAt,
    DateTime? disputedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      estimatedPriceFcfa: estimatedPriceFcfa ?? this.estimatedPriceFcfa,
      actualPriceFcfa: actualPriceFcfa ?? this.actualPriceFcfa,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      actualDurationMin: actualDurationMin ?? this.actualDurationMin,
      pricingSnapshot: pricingSnapshot ?? this.pricingSnapshot,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gpsLogBlobUrl: gpsLogBlobUrl ?? this.gpsLogBlobUrl,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      driverArrivedAt: driverArrivedAt ?? this.driverArrivedAt,
      startedAt: startedAt ?? this.startedAt,
      driverConfirmedAt: driverConfirmedAt ?? this.driverConfirmedAt,
      passengerConfirmedAt: passengerConfirmedAt ?? this.passengerConfirmedAt,
      autoConfirmedAt: autoConfirmedAt ?? this.autoConfirmedAt,
      completedAt: completedAt ?? this.completedAt,
      disputedAt: disputedAt ?? this.disputedAt,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      passengerId: json['passengerId'] as String,
      driverId: json['driverId'] as String?,
      pickupLocation: LatLng(
        (json['pickupLocation']['lat'] as num).toDouble(),
        (json['pickupLocation']['lng'] as num).toDouble(),
      ),
      dropoffLocation: LatLng(
        (json['dropoffLocation']['lat'] as num).toDouble(),
        (json['dropoffLocation']['lng'] as num).toDouble(),
      ),
      pickupAddress: json['pickupAddress'] as String?,
      dropoffAddress: json['dropoffAddress'] as String?,
      estimatedPriceFcfa: json['estimatedPriceFcfa'] as int?,
      actualPriceFcfa: json['actualPriceFcfa'] as int?,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
      actualDistanceKm: (json['actualDistanceKm'] as num?)?.toDouble(),
      estimatedDurationMin: json['estimatedDurationMin'] as int?,
      actualDurationMin: json['actualDurationMin'] as int?,
      pricingSnapshot: json['pricingSnapshot'] as Map<String, dynamic>?,
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.searching,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.wave,
      ),
      gpsLogBlobUrl: json['gpsLogBlobUrl'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledBy: json['cancelledBy'] != null
          ? TripCancellationBy.values.firstWhere(
              (e) => e.name == json['cancelledBy'],
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      driverArrivedAt: json['driverArrivedAt'] != null
          ? DateTime.parse(json['driverArrivedAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      driverConfirmedAt: json['driverConfirmedAt'] != null
          ? DateTime.parse(json['driverConfirmedAt'] as String)
          : null,
      passengerConfirmedAt: json['passengerConfirmedAt'] != null
          ? DateTime.parse(json['passengerConfirmedAt'] as String)
          : null,
      autoConfirmedAt: json['autoConfirmedAt'] != null
          ? DateTime.parse(json['autoConfirmedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      disputedAt: json['disputedAt'] != null
          ? DateTime.parse(json['disputedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'driverId': driverId,
      'pickupLocation': {
        'lat': pickupLocation.latitude,
        'lng': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'lat': dropoffLocation.latitude,
        'lng': dropoffLocation.longitude,
      },
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'estimatedPriceFcfa': estimatedPriceFcfa,
      'actualPriceFcfa': actualPriceFcfa,
      'estimatedDistanceKm': estimatedDistanceKm,
      'actualDistanceKm': actualDistanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'actualDurationMin': actualDurationMin,
      'pricingSnapshot': pricingSnapshot,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'gpsLogBlobUrl': gpsLogBlobUrl,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy?.name,
      'createdAt': createdAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'driverArrivedAt': driverArrivedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'driverConfirmedAt': driverConfirmedAt?.toIso8601String(),
      'passengerConfirmedAt': passengerConfirmedAt?.toIso8601String(),
      'autoConfirmedAt': autoConfirmedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'disputedAt': disputedAt?.toIso8601String(),
    };
  }
}

enum TripStatus {
  @JsonValue('searching')
  searching,
  @JsonValue('accepted')
  accepted,
  @JsonValue('driver_en_route')
  driverEnRoute,
  @JsonValue('driver_arrived')
  driverArrived,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('driver_confirmed')
  driverConfirmed,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('disputed')
  disputed,
}

enum TripCancellationBy {
  @JsonValue('passenger')
  passenger,
  @JsonValue('driver')
  driver,
  @JsonValue('system')
  system,
  @JsonValue('admin')
  admin,
}

enum PaymentMethod {
  @JsonValue('wave')
  wave,
  @JsonValue('orange_money')
  orangeMoney,
}
