import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) => SignalRService());

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  SignalRService._internal();

  io.Socket? _socket;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isConnected = false;
  static const LatLng _defaultDakar = LatLng(14.6928, -17.4467);

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    await connect();
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      _isConnected = true;
      return;
    }

    final token = await _secureStorage.read(key: 'auth_token');
    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders(
            token == null ? {} : {'authorization': 'Bearer $token'},
          )
          .build(),
    );

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

    _registerConnectionHandlers();
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void _registerConnectionHandlers() {
    _socket?.on('connect', (_) => _isConnected = true);
    _socket?.on('disconnect', (_) => _isConnected = false);
  }

  // Driver location updates during trip
  void onDriverLocationUpdate(Function(Driver driver) callback) {
    _socket?.on('driver:location-updated', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      final driver = Driver(
        id: (data['driverId'] ?? '').toString(),
        userId: (data['driverId'] ?? '').toString(),
        name: 'Chauffeur',
        rating: 5,
        status: DriverStatus.active,
        isAvailable: true,
        location: data['lat'] != null && data['lng'] != null
            ? LatLng(
                (data['lat'] as num).toDouble(),
                (data['lng'] as num).toDouble(),
              )
            : null,
      );
      callback(driver);
    });
  }

  // Trip status updates
  void onTripStatusUpdate(Function(Trip trip) callback) {
    _socket?.on('trip:started', (payload) => _emitTripCallback(payload, callback));
    _socket?.on('trip:completed', (payload) => _emitTripCallback(payload, callback));
  }

  // Payment status updates
  void onPaymentStatusUpdate(Function(String tripId, String status) callback) {
    _socket?.on('payment:received', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      callback((data['tripId'] ?? '').toString(), 'received');
    });
  }

  // Driver found notification
  void onDriverFound(Function(Driver driver, Trip trip) callback) {
    _socket?.on('driver:accepted', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);

      final driver = Driver(
        id: (data['driverId'] ?? '').toString(),
        userId: (data['driverId'] ?? '').toString(),
        name: (data['driverName'] ?? 'Chauffeur').toString(),
        motoModel: (data['motoModel'] ?? '').toString(),
        plateNumber: (data['plateNumber'] ?? '').toString(),
        rating: ((data['driverRating'] ?? 5) as num).toDouble(),
        status: DriverStatus.active,
        isAvailable: true,
      );

      final trip = Trip(
        id: (data['tripId'] ?? '').toString(),
        passengerId: 'me',
        pickupLocation: _defaultDakar,
        dropoffLocation: _defaultDakar,
        status: TripStatus.driverEnRoute,
        paymentMethod: PaymentMethod.wave,
        createdAt: DateTime.now(),
      );

      callback(driver, trip);
    });
  }

  // Trip completed notification
  void onTripCompleted(Function(Trip trip) callback) {
    _socket?.on('trip:completed', (payload) => _emitTripCallback(payload, callback));
  }

  // Driver arrived notification
  void onDriverArrived(Function(String tripId) callback) {
    _socket?.on('driver:arrived', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      callback((data['tripId'] ?? '').toString());
    });
  }

  // Send location updates during trip
  Future<void> sendLocationUpdate(String tripId, double lat, double lng) async {
    if (!_isConnected) return;

    try {
      _socket?.emit('passenger:location', {
        'tripId': tripId,
        'lat': lat,
        'lng': lng,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send location update: $e');
    }
  }

  // Confirm trip arrival
  Future<void> confirmTripArrival(String tripId) async {
    if (!_isConnected) return;

    try {
      _socket?.emit('trip:confirm-arrival', {'tripId': tripId});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to confirm trip arrival: $e');
    }
  }

  // Dispute trip
  Future<void> disputeTrip(String tripId, String reason) async {
    if (!_isConnected) return;

    try {
      _socket?.emit('trip:dispute', {'tripId': tripId, 'reason': reason});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to dispute trip: $e');
    }
  }

  // Join trip room
  Future<void> joinTripRoom(String tripId) async {
    if (!_isConnected) return;

    try {
      _socket?.emit('trip:join', {'tripId': tripId});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to join trip room: $e');
    }
  }

  // Leave trip room
  Future<void> leaveTripRoom(String tripId) async {
    if (!_isConnected) return;

    try {
      _socket?.emit('trip:leave', {'tripId': tripId});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to leave trip room: $e');
    }
  }

  void _emitTripCallback(
    dynamic payload,
    Function(Trip trip) callback,
  ) {
    if (payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);

    final trip = Trip(
      id: (data['tripId'] ?? '').toString(),
      passengerId: 'me',
      pickupLocation: _defaultDakar,
      dropoffLocation: _defaultDakar,
      status: (data['status'] == 'completed')
          ? TripStatus.completed
          : TripStatus.inProgress,
      paymentMethod: PaymentMethod.wave,
      createdAt: DateTime.now(),
    );

    callback(trip);
  }
}

