import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/price_estimate.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/models/driver.dart';

class ApiClient {
  static const String baseUrl = '${AppConstants.baseUrl}/api';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = 
      const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        contentType: 'application/json',
      ),
    );

    // Add interceptor for token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _authTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _secureStorage.delete(key: _authTokenKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._();

  factory ApiClient() {
    return _instance;
  }

  /// AUTH ENDPOINTS
  
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'code': code},
      );
      
      // Store token
      final accessToken =
          (response.data['accessToken'] ?? response.data['token']) as String?;
      final refreshToken = response.data['refreshToken'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        await _secureStorage.write(
          key: _authTokenKey,
          value: accessToken,
        );
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: refreshToken,
        );
      }
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// PRICING ENDPOINTS

  Future<PriceEstimate> estimatePrice({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    try {
      final response = await _dio.get(
        '/trips/estimate',
        queryParameters: {
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
        },
      );
      return PriceEstimate.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// TRIP ENDPOINTS

  Future<Map<String, dynamic>> requestTrip({
    required LatLng pickup,
    required LatLng dropoff,
    required String pickupAddress,
    required String dropoffAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        '/trips/request',
        data: {
          'pickup': {
            'lat': pickup.latitude,
            'lng': pickup.longitude,
            'address': pickupAddress,
          },
          'dropoff': {
            'lat': dropoff.latitude,
            'lng': dropoff.longitude,
            'address': dropoffAddress,
          },
          'payment_method': paymentMethod,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      rethrow;
    }
  }

  Future<Trip> createTrip({
    required String tripId,
    required String paymentMethod,
  }) async {
    throw UnimplementedError(
      'Use requestTrip with pickup/dropoff instead of createTrip',
    );
  }

  Future<Trip> getTrip(String tripId) async {
    try {
      final response = await _dio.get('/trips/$tripId');
      return Trip.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelTrip(String tripId) async {
    try {
      await _dio.put('/trips/$tripId/cancel');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmArrival(String tripId) async {
    try {
      final response = await _dio.post(
        '/trips/$tripId/passenger-confirm',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> disputeTrip({
    required String tripId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/trips/$tripId/dispute',
        data: {'reason': reason},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// RATING ENDPOINTS

  Future<void> rateTrip({
    required String tripId,
    required int score,
    required List<String> tags,
    String? comment,
    int? tipAmount,
  }) async {
    try {
      await _dio.post(
        '/trips/$tripId/rate',
        data: {
          'score': score,
          'tags': tags,
          'comment': comment,
          'tip_amount_fcfa': tipAmount ?? 0,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PAYMENT ENDPOINTS

  Future<Map<String, dynamic>> initiatePayment({
    required String tripId,
    required String method,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/initiate',
        data: {
          'trip_id': tripId,
          'method': method,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Trip>> getPassengerHistory({String? method}) async {
    try {
      final response = await _dio.get(
        '/trips/history',
        queryParameters: method == null ? null : {'method': method},
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final trips = (data['trips'] as List<dynamic>? ?? const []);

      return trips.map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        final driver = json['driver'] as Map<String, dynamic>?;
        final completedAt = json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null;

        return Trip(
          id: json['id'] as String,
          passengerId: 'me',
          driverId: driver?['id'] as String?,
          pickupLocation: const LatLng(14.6928, -17.4467),
          dropoffLocation: const LatLng(14.7416, -17.5104),
          pickupAddress: json['pickupAddress'] as String?,
          dropoffAddress: json['dropoffAddress'] as String?,
          estimatedPriceFcfa: json['price_fcfa'] as int?,
          actualPriceFcfa: json['price_fcfa'] as int?,
          actualDistanceKm: (json['distance_km'] as num?)?.toDouble(),
          actualDurationMin: json['duration_min'] as int?,
          status: TripStatus.completed,
          paymentMethod: (json['method'] == 'orange_money')
              ? PaymentMethod.orangeMoney
              : PaymentMethod.wave,
          completedAt: completedAt,
          createdAt: completedAt,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// LOCATION ENDPOINTS

  Future<void> updatePassengerLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _dio.post(
        '/trips/$tripId/passenger-location',
        data: {
          'lat': lat,
          'lng': lng,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DRIVER ENDPOINTS

  Future<List<Driver>> getAvailableDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        '/drivers/available',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
      );
      return (response.data['drivers'] as List)
          .map((d) => Driver.fromJson(d))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Driver> getDriver(String driverId) async {
    try {
      final response = await _dio.get('/drivers/$driverId');
      return Driver.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// UTILITY

  void setAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }

    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
}

