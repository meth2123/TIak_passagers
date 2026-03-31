import 'package:flutter/material.dart';

/// Service de calcul de tarification dynamique
/// Basé sur agents.md specifications
class PricingService {
  static final PricingService _instance = PricingService._internal();

  // Configuration par défaut (matching agents.md)
  static const int BASE_FARE_FCFA = 300;
  static const int PRICE_PER_KM_FCFA = 180;
  static const int MINIMUM_FARE_FCFA = 500;
  static const double COMMISSION_PCT = 0.20; // 20%

  // Heure pointe
  static const String PEAK_MORNING_START = '06:30';
  static const String PEAK_MORNING_END = '09:30';
  static const String PEAK_EVENING_START = '17:00';
  static const String PEAK_EVENING_END = '20:30';
  static const double PEAK_MULTIPLIER = 1.30;

  // Nuit
  static const String NIGHT_START = '22:00';
  static const String NIGHT_END = '05:00';
  static const double NIGHT_MULTIPLIER = 1.20;

  // Pluie
  static const double RAIN_MULTIPLIER = 1.40;
  static const double HEAVY_RAIN_MULTIPLIER = 1.60;

  // Surcharge demande (nombre de chauffeurs disponibles)
  static const double SURGE_3DRIVERS = 1.10;
  static const double SURGE_2DRIVERS = 1.25;
  static const double SURGE_1DRIVER = 1.40;
  static const double MAX_SURGE_COMBINED = 1.80;

  // Prix final plafond vs estimation
  static const double PRICE_CAP_RATIO = 1.20;

  PricingService._internal();

  factory PricingService() {
    return _instance;
  }

  /// Calcule le prix estimé pour une course
  /// @param distanceKm: Distance en kilomètres (from Mapbox)
  /// @param availableDrivers: Nombre de chauffeurs dispo (< 5km)
  /// @param isRaining: Il pleut? (from OpenWeatherMap)
  /// @param rainIntensity: Intensité pluie (mm/h)
  /// @return Map avec prix, breakdown, multiplicateurs
  Map<String, dynamic> calculatePrice({
    required double distanceKm,
    required int availableDrivers,
    bool isRaining = false,
    double rainIntensity = 0.0,
  }) {
    // Step 1: Base calculation
    final baseFare = BASE_FARE_FCFA;
    final distanceCost = (PRICE_PER_KM_FCFA * distanceKm).toInt();
    int subtotal = baseFare + distanceCost;

    // Step 2: Apply minimum fare
    if (subtotal < MINIMUM_FARE_FCFA) {
      subtotal = MINIMUM_FARE_FCFA;
    }

    // Step 3: Calculate multiplicators (pick the highest)
    double multiplier = 1.0;
    String? multiplierReason;

    // Peak hours multiplier
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    if (_isPeakHours(currentTime)) {
      multiplier = PEAK_MULTIPLIER;
      multiplierReason = '⚡ Heure de pointe +30%';
    }

    // Night multiplier
    if (_isNight(currentTime) && multiplier < NIGHT_MULTIPLIER) {
      multiplier = NIGHT_MULTIPLIER;
      multiplierReason = '🌙 Tarif nuit +20%';
    }

    // Rain multiplier
    if (isRaining) {
      double rainMult = rainIntensity > 10.0
          ? HEAVY_RAIN_MULTIPLIER
          : RAIN_MULTIPLIER;
      if (rainMult > multiplier) {
        multiplier = rainMult;
        multiplierReason = rainIntensity > 10.0
            ? '🌧️ Forte pluie +60%'
            : '🌧️ Surcharge pluie +40%';
      }
    }

    // Surge multiplier (available drivers)
    double surgeMult = 1.0;
    String? surgeReason;
    if (availableDrivers == 1) {
      surgeMult = SURGE_1DRIVER;
      surgeReason = 'Très haute demande';
    } else if (availableDrivers == 2) {
      surgeMult = SURGE_2DRIVERS;
      surgeReason = 'Haute demande';
    } else if (availableDrivers == 3) {
      surgeMult = SURGE_3DRIVERS;
      surgeReason = 'Demande normale';
    }

    // Apply highest multiplier OR capped combination
    if (surgeMult > multiplier && surgeMult <= MAX_SURGE_COMBINED) {
      multiplier = surgeMult;
      multiplierReason = surgeReason;
    }

    // Step 4: Apply multiplier & round to 50 FCFA
    int estimatedPrice =
        _roundTo50Fcfa((subtotal * multiplier).toInt());

    // Step 5: Apply price cap (max 120% of subtotal)
    final priceCapAmount = (subtotal * PRICE_CAP_RATIO).toInt();
    if (estimatedPrice > priceCapAmount) {
      estimatedPrice = priceCapAmount;
    }

    // Step 6: Calculate 80/20 split
    final commissionAmount = (estimatedPrice * COMMISSION_PCT).toInt();
    final driverPayoutAmount = estimatedPrice - commissionAmount;

    return {
      'estimated_price_fcfa': estimatedPrice,
      'price_min_fcfa':
          (estimatedPrice * 0.95).toInt(), // -5% variance
      'price_max_fcfa':
          (estimatedPrice * 1.05).toInt(), // +5% variance
      'distance_km': distanceKm.toStringAsFixed(1),
      'duration_min': _estimateDuration(distanceKm),
      'breakdown': {
        'base_fare': baseFare,
        'distance_cost': distanceCost,
        'subtotal': subtotal,
        'multiplier': multiplier.toStringAsFixed(2),
        'multiplier_reason': multiplierReason,
        'rounded_to': estimatedPrice,
      },
      'commission_fcfa': commissionAmount,
      'driver_payout_fcfa': driverPayoutAmount,
      'surge_active': multiplier > 1.0,
      'surge_reason': multiplierReason,
    };
  }

  /// Check if current time is peak hours
  bool _isPeakHours(TimeOfDay currentTime) {
    final morning = _isTimeBetween(
      currentTime,
      '06:30',
      '09:30',
    );
    final evening = _isTimeBetween(
      currentTime,
      '17:00',
      '20:30',
    );
    return morning || evening;
  }

  /// Check if current time is night
  bool _isNight(TimeOfDay currentTime) {
    return _isTimeBetween(currentTime, '22:00', '05:00');
  }

  /// Check if time is between start and end
  bool _isTimeBetween(
    TimeOfDay current,
    String startStr,
    String endStr,
  ) {
    final startParts = startStr.split(':');
    final endParts = endStr.split(':');

    final startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );
    final endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    // Handle overnight (22:00 - 05:00)
    if (startTime.hour > endTime.hour) {
      return current.hour >= startTime.hour ||
          current.hour < endTime.hour;
    }

    return current.hour > startTime.hour ||
        (current.hour == startTime.hour &&
            current.minute >= startTime.minute) &&
        (current.hour < endTime.hour ||
            (current.hour == endTime.hour &&
                current.minute < endTime.minute));
  }

  /// Round to nearest 50 FCFA (always up)
  int _roundTo50Fcfa(int amount) {
    final remainder = amount % 50;
    if (remainder == 0) return amount;
    return amount + (50 - remainder);
  }

  /// Estimate duration based on distance
  /// Assume ~25 km/h average speed in Dakar
  int _estimateDuration(double distanceKm) {
    final minutes = (distanceKm / 25 * 60).toInt();
    return minutes < 1 ? 1 : minutes;
  }
}

