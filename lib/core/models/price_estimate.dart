class PriceEstimate {
  final int estimatedPriceFcfa;
  final int? priceMinFcfa;
  final int? priceMaxFcfa;
  final double distanceKm;
  final int durationMin;
  final Map<String, dynamic>? breakdown;
  final bool? surgeActive;
  final String? surgeReason;

  const PriceEstimate({
    required this.estimatedPriceFcfa,
    this.priceMinFcfa,
    this.priceMaxFcfa,
    required this.distanceKm,
    required this.durationMin,
    this.breakdown,
    this.surgeActive,
    this.surgeReason,
  });

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.round();
      return fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return fallback;
    }

    final estimatedPrice =
        json['estimated_price_fcfa'] ?? json['estimatedPriceFcfa'];
    final priceMin = json['price_min_fcfa'] ?? json['priceMinFcfa'];
    final priceMax = json['price_max_fcfa'] ?? json['priceMaxFcfa'];
    final distance = json['distance_km'] ?? json['distanceKm'];
    final duration = json['duration_min'] ?? json['durationMin'];
    final surgeActive = json['surge_active'] ?? json['surgeActive'];
    final surgeReason = json['surge_reason'] ?? json['surgeReason'];

    return PriceEstimate(
      estimatedPriceFcfa: asInt(estimatedPrice),
      priceMinFcfa: priceMin != null ? asInt(priceMin) : null,
      priceMaxFcfa: priceMax != null ? asInt(priceMax) : null,
      distanceKm: asDouble(distance),
      durationMin: asInt(duration),
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      surgeActive: surgeActive as bool?,
      surgeReason: surgeReason as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedPriceFcfa': estimatedPriceFcfa,
      'priceMinFcfa': priceMinFcfa,
      'priceMaxFcfa': priceMaxFcfa,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'breakdown': breakdown,
      'surgeActive': surgeActive,
      'surgeReason': surgeReason,
    };
  }
}

class PriceBreakdown {
  final int baseFare;
  final int distanceCost;
  final int subtotal;
  final double multiplier;
  final String? multiplierReason;
  final int roundedTo;

  const PriceBreakdown({
    required this.baseFare,
    required this.distanceCost,
    required this.subtotal,
    required this.multiplier,
    this.multiplierReason,
    required this.roundedTo,
  });

  factory PriceBreakdown.fromJson(Map<String, dynamic> json) {
    return PriceBreakdown(
      baseFare: json['baseFare'] as int,
      distanceCost: json['distanceCost'] as int,
      subtotal: json['subtotal'] as int,
      multiplier: (json['multiplier'] as num).toDouble(),
      multiplierReason: json['multiplierReason'] as String?,
      roundedTo: json['roundedTo'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'distanceCost': distanceCost,
      'subtotal': subtotal,
      'multiplier': multiplier,
      'multiplierReason': multiplierReason,
      'roundedTo': roundedTo,
    };
  }
}
