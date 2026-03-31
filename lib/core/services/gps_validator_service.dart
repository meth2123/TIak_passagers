import 'package:geolocator/geolocator.dart';

/// Service de validation GPS (4 verrous anti-fraude)
/// Basé sur agents.md specifications
class GpsValidatorService {
  static final GpsValidatorService _instance = GpsValidatorService._internal();

  // Configuration des verrous (modifiable depuis admin)
  static const double LOCK_1_RADIUS_M = 150.0; // Proximité destination
  static const double LOCK_2_DISTANCE_RATIO = 0.70; // 70% distance min
  static const double LOCK_3_DURATION_RATIO = 0.60; // 60% durée min
  static const double LOCK_4_PASSENGER_RADIUS_M = 300.0; // Rayon passager

  GpsValidatorService._internal();

  factory GpsValidatorService() {
    return _instance;
  }

  /// Valide les 4 verrous GPS pour terminer une course
  /// Retourne un objet avec statut et raison d'échec
  Map<String, dynamic> validateCompletion({
    required Position driverPosition,
    required Position destinationLatLng,
    required double actualDistanceKm,
    required double estimatedDistanceKm,
    required int actualDurationMin,
    required int estimatedDurationMin,
    Position? passengerPosition,
  }) {
    // VERROU 1: Proximité destination (max 150m)
    final distanceToDestination = Geolocator.distanceBetween(
      driverPosition.latitude,
      driverPosition.longitude,
      destinationLatLng.latitude,
      destinationLatLng.longitude,
    );

    if (distanceToDestination > LOCK_1_RADIUS_M) {
      return {
        'valid': false,
        'lock_failed': 1,
        'reason': 'DRIVER_TOO_FAR',
        'message':
            'Vous êtes à ${(distanceToDestination / 1000).toStringAsFixed(2)}km de la destination',
        'distance_to_dest_m': distanceToDestination,
      };
    }

    // VERROU 2: Distance réelle ≥ 70% de l'estimée
    final distanceRatio = actualDistanceKm / estimatedDistanceKm;

    if (distanceRatio < LOCK_2_DISTANCE_RATIO) {
      final completionPct = (distanceRatio * 100).toInt();
      return {
        'valid': false,
        'lock_failed': 2,
        'reason': 'ROUTE_INCOMPLETE',
        'message':
            'Trajet incomplet : $completionPct% parcouru',
        'actual_distance_km': actualDistanceKm,
        'estimated_distance_km': estimatedDistanceKm,
        'completion_pct': completionPct,
      };
    }

    // Check for detour (actual > estimated + 20%)
    if (actualDistanceKm > (estimatedDistanceKm * 1.20)) {
      return {
        'valid': false,
        'lock_failed': 2,
        'reason': 'EXCESSIVE_DETOUR',
        'message': 'Détour excessif détecté',
        'actual_distance_km': actualDistanceKm,
        'estimated_distance_km': estimatedDistanceKm,
      };
    }

    // VERROU 3: Durée ≥ 60% de l'estimée
    final durationRatio = actualDurationMin / estimatedDurationMin;

    if (durationRatio < LOCK_3_DURATION_RATIO) {
      final completionPct = (durationRatio * 100).toInt();

      // Si distance aussi échoue → double blocage
      if (distanceRatio < LOCK_2_DISTANCE_RATIO) {
        return {
          'valid': false,
          'lock_failed': 3,
          'reason': 'DURATION_TOO_SHORT',
          'message': 'Durée insuffisante: $completionPct% de l\'estimée',
          'actual_duration_min': actualDurationMin,
          'estimated_duration_min': estimatedDurationMin,
          'completion_pct': completionPct,
        };
      }
      // Sinon → accepté (route rapide)
    }

    // VERROU 4: Position passager (si disponible)
    if (passengerPosition != null) {
      final passengerDistance = Geolocator.distanceBetween(
        passengerPosition.latitude,
        passengerPosition.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );

      if (passengerDistance > LOCK_4_PASSENGER_RADIUS_M) {
        // Accepté MAIS timer raccourci à 2 min
        return {
          'valid': true,
          'warning': 'PASSENGER_NOT_AT_DEST',
          'timer_override_min': 2,
          'passenger_distance_m': passengerDistance,
          'message':
              'Votre chauffeur indique être arrivé. Vous confirmez ?',
        };
      }
    }

    // Tous les verrous passés ✓
    return {
      'valid': true,
      'message': 'Tous les verrous validés ✓',
      'distance_to_dest_m': distanceToDestination,
      'completion_pct': (distanceRatio * 100).toInt(),
    };
  }

  /// Obtient la couleur du bouton "Terminer" selon les critères
  String getButtonStatus({
    required double actualDistanceKm,
    required double estimatedDistanceKm,
    required double distanceToDestinationM,
  }) {
    final distanceRatio = actualDistanceKm / estimatedDistanceKm;

    // GRIS: trajet < 70% OU distance >> destination
    if (distanceRatio < LOCK_2_DISTANCE_RATIO ||
        distanceToDestinationM > LOCK_1_RADIUS_M) {
      return 'grey';
    }

    // ORANGE: proche mais pas encore à destination
    if (distanceToDestinationM > 50.0) {
      return 'orange';
    }

    // VERT: tous critères OK
    return 'green';
  }
}

