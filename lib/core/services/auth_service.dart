import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/user.dart';
import 'package:tiak_passenger/core/services/api_client.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  static const String _tokenKey = AppConstants.storageUserToken;
  static const String _userDataKey = AppConstants.storageUserData;
  static const String _onboardingKey = 'onboarding_completed';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _promoNotificationsEnabledKey =
      'promo_notifications_enabled';

  late Box _appBox;
  final ApiClient _apiClient = ApiClient();
  bool _initialized = false;

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _appBox = await Hive.openBox('app_data');
    _initialized = true;
  }

  // Authentication state
  bool get isAuthenticated => _getToken() != null;
  bool get isOnboardingCompleted =>
      _appBox.get(_onboardingKey, defaultValue: false);
  bool get notificationsEnabled =>
      _appBox.get(_notificationsEnabledKey, defaultValue: true);
  bool get promoNotificationsEnabled =>
      _appBox.get(_promoNotificationsEnabledKey, defaultValue: true);

  String? _getToken() {
    // In a real app, this would be stored securely
    return _appBox.get(_tokenKey);
  }

  Future<void> setToken(String token) async {
    await _appBox.put(_tokenKey, token);
  }

  Future<void> setUserData(User user) async {
    await _appBox.put(_userDataKey, user.toJson());
  }

  User? getUserData() {
    final userData = _appBox.get(_userDataKey);
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _appBox.put(_onboardingKey, completed);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _appBox.put(_notificationsEnabledKey, enabled);
  }

  Future<void> setPromoNotificationsEnabled(bool enabled) async {
    await _appBox.put(_promoNotificationsEnabledKey, enabled);
  }

  Future<void> logout() async {
    await _appBox.delete(_tokenKey);
    await _appBox.delete(_userDataKey);
    await _apiClient.logout();
    if (!kIsWeb) {
      await SignalRService().disconnect();
    }
  }

  // Auth methods
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      await _apiClient.sendOtp(phoneNumber);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _apiClient.verifyOtp(phone: phoneNumber, code: otp);
      final token = (response['token'] ?? response['accessToken']) as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userJson = response['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        return false;
      }

      final user = User.fromJson(userJson);

      await setToken(token);
      _apiClient.setAuthToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.setRefreshToken(refreshToken);
      }
      await setUserData(user);
      if (!kIsWeb) {
        await SignalRService().connect();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
    PaymentMethod? preferredPayment,
    Language? language,
  }) async {
    final currentUser = getUserData();
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        preferredPayment: preferredPayment ?? currentUser.preferredPayment,
        lang: language ?? currentUser.lang,
      );
      await setUserData(updatedUser);
    }
  }
}
