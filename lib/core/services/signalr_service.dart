import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';

final signalRServiceProvider = Provider<SignalRService>(
  (ref) => SignalRService(),
);

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  SignalRService._internal();

  static const LatLng _defaultDakar = LatLng(14.6928, -17.4467);
  static const String _driverLocationEvent = 'driver:location-updated';
  static const String _tripStartedEvent = 'trip:started';
  static const String _tripCompletedEvent = 'trip:completed';
  static const String _paymentReceivedEvent = 'payment:received';
  static const String _driverAcceptedEvent = 'driver:accepted';
  static const String _driverArrivedEvent = 'driver:arrived';
  static const String _etaUpdatedEvent = 'driver:eta-updated';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _socket?.connected ?? _isConnected;

  Future<void> initialize() async {
    await connect();
  }

  Future<void> connect() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      await disconnect();
      return;
    }

    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .build(),
    );

    _registerConnectionHandlers();
    _socket?.connect();
  }

  Future<void> disconnect() async {
    clearPassengerListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void clearPassengerListeners() {
    for (final event in const [
      _driverLocationEvent,
      _tripStartedEvent,
      _tripCompletedEvent,
      _paymentReceivedEvent,
      _driverAcceptedEvent,
      _driverArrivedEvent,
      _etaUpdatedEvent,
    ]) {
      _socket?.off(event);
    }
  }

  void onDriverLocationUpdate({
    String? driverId,
    required void Function(Driver driver) callback,
  }) {
    _socket?.off(_driverLocationEvent);
    _socket?.on(_driverLocationEvent, (payload) {
      final data = _asMap(payload);
      if (data == null) {
        return;
      }

      final driver = Driver(
        id: (data['driverId'] ?? '').toString(),
        userId: (data['driverId'] ?? '').toString(),
        name: (data['driverName'] ?? 'Chauffeur').toString(),
        phoneNumber: data['driverPhone']?.toString(),
        rating: ((data['driverRating'] ?? 5) as num).toDouble(),
        status: DriverStatus.active,
        isAvailable: true,
        location: data['lat'] != null && data['lng'] != null
            ? LatLng(
                (data['lat'] as num).toDouble(),
                (data['lng'] as num).toDouble(),
              )
            : null,
      );

      if (driverId != null && driver.id != driverId) {
        return;
      }

      callback(driver);
    });
  }

  void onTripStatusUpdate({
    String? tripId,
    required void Function(Trip trip) callback,
  }) {
    _socket?.off(_tripStartedEvent);
    _socket?.off(_tripCompletedEvent);

    _socket?.on(
      _tripStartedEvent,
      (payload) => _emitTripCallback(
        payload,
        tripId: tripId,
        status: TripStatus.inProgress,
        callback: callback,
      ),
    );
    _socket?.on(
      _tripCompletedEvent,
      (payload) => _emitTripCallback(
        payload,
        tripId: tripId,
        status: TripStatus.completed,
        callback: callback,
      ),
    );
  }

  void onPaymentStatusUpdate({
    String? tripId,
    required void Function(String tripId, String status) callback,
  }) {
    _socket?.off(_paymentReceivedEvent);
    _socket?.on(_paymentReceivedEvent, (payload) {
      final data = _asMap(payload);
      if (data == null) {
        return;
      }

      final receivedTripId = (data['tripId'] ?? '').toString();
      if (tripId != null && receivedTripId != tripId) {
        return;
      }

      callback(receivedTripId, 'received');
    });
  }

  void onDriverFound({
    required void Function(Driver driver) callback,
  }) {
    _socket?.off(_driverAcceptedEvent);
    _socket?.on(_driverAcceptedEvent, (payload) {
      final data = _asMap(payload);
      if (data == null) {
        return;
      }

      callback(
        Driver(
          id: (data['driverId'] ?? '').toString(),
          userId: (data['driverId'] ?? '').toString(),
          name: (data['driverName'] ?? 'Chauffeur').toString(),
          phoneNumber: data['driverPhone']?.toString(),
          motoModel: (data['motoModel'] ?? '').toString(),
          plateNumber: (data['plateNumber'] ?? '').toString(),
          rating: ((data['driverRating'] ?? 5) as num).toDouble(),
          status: DriverStatus.active,
          isAvailable: true,
          location: data['lat'] != null && data['lng'] != null
              ? LatLng(
                  (data['lat'] as num).toDouble(),
                  (data['lng'] as num).toDouble(),
                )
              : null,
        ),
      );
    });
  }

  void onDriverArrived({
    required void Function() callback,
  }) {
    _socket?.off(_driverArrivedEvent);
    _socket?.on(_driverArrivedEvent, (_) => callback());
  }

  void onEtaUpdated({
    required void Function(int etaMinutes, double driverLat, double driverLng)
        callback,
  }) {
    _socket?.off(_etaUpdatedEvent);
    _socket?.on(_etaUpdatedEvent, (payload) {
      final data = _asMap(payload);
      if (data == null) {
        return;
      }

      callback(
        ((data['etaMinutes'] ?? 0) as num).toInt(),
        ((data['driverLat'] ?? _defaultDakar.latitude) as num).toDouble(),
        ((data['driverLng'] ?? _defaultDakar.longitude) as num).toDouble(),
      );
    });
  }

  Future<void> sendLocationUpdate(String tripId, double lat, double lng) async {
    if (!isConnected) {
      return;
    }

    _socket?.emit('passenger:location', {
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> confirmTripArrival(String tripId) async {
    if (!isConnected) {
      return;
    }

    _socket?.emit('trip:confirm-arrival', {'tripId': tripId});
  }

  Future<void> disputeTrip(String tripId, String reason) async {
    if (!isConnected) {
      return;
    }

    _socket?.emit('trip:dispute', {'tripId': tripId, 'reason': reason});
  }

  Future<void> joinTripRoom(String tripId) async {
    if (!isConnected) {
      return;
    }

    _socket?.emit('trip:join', {'tripId': tripId});
  }

  Future<void> leaveTripRoom(String tripId) async {
    if (!isConnected) {
      return;
    }

    _socket?.emit('trip:leave', {'tripId': tripId});
  }

  void _registerConnectionHandlers() {
    _socket?.onConnect((_) {
      _isConnected = true;
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
    });

    _socket?.onConnectError((error) {
      _isConnected = false;
      // ignore: avoid_print
      print('Socket connection failed: $error');
    });
  }

  void _emitTripCallback(
    dynamic payload, {
    String? tripId,
    required TripStatus status,
    required void Function(Trip trip) callback,
  }) {
    final data = _asMap(payload);
    if (data == null) {
      return;
    }

    final receivedTripId = (data['tripId'] ?? '').toString();
    if (tripId != null && receivedTripId != tripId) {
      return;
    }

    callback(
      Trip(
        id: receivedTripId,
        passengerId: 'me',
        pickupLocation: _defaultDakar,
        dropoffLocation: _defaultDakar,
        status: status,
        paymentMethod: PaymentMethod.wave,
        createdAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }
}
