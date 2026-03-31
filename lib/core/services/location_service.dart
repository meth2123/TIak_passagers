import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;

  LatLng? get currentPosition => _currentPosition;

  Future<void> initialize() async {
    await _requestPermissions();
  }

  Future<bool> _requestPermissions() async {
    final locationPermission = await Permission.location.request();
    final backgroundPermission = await Permission.locationAlways.request();

    return locationPermission.isGranted && backgroundPermission.isGranted;
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = LatLng(position.latitude, position.longitude);
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  Future<void> startLocationUpdates({
    required Function(LatLng position) onLocationUpdate,
    bool enableBackground = false,
  }) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    // Stop existing streams
    await stopLocationUpdates();

    if (enableBackground) {
      await _startBackgroundLocationUpdates(onLocationUpdate);
    } else {
      await _startForegroundLocationUpdates(onLocationUpdate);
    }
  }

  Future<void> _startForegroundLocationUpdates(Function(LatLng) onLocationUpdate) async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      onLocationUpdate(_currentPosition!);
    });
  }

  Future<void> _startBackgroundLocationUpdates(Function(LatLng) onLocationUpdate) async {
    // Fallback: foreground stream only until background tracking is wired.
    await _startForegroundLocationUpdates(onLocationUpdate);
  }

  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<String?> getAddressFromCoordinates(LatLng position) async {
    // TODO: Implement reverse geocoding using Mapbox API
    // For now, return mock address
    return 'Adresse approximative, Dakar';
  }

  Future<List<LatLng>> searchPlaces(String query) async {
    // TODO: Implement place search using Mapbox Search API
    // For now, return mock results
    return [
      const LatLng(14.6937, -17.4441), // Plateau, Dakar
      const LatLng(14.7167, -17.4677), // Médina, Dakar
    ];
  }

  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
}

