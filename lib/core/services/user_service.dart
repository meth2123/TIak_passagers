import 'package:tiak_passenger/core/models/user.dart';
import 'package:tiak_passenger/core/services/api_client.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final ApiClient _apiClient = ApiClient();

  UserService._internal();

  factory UserService() {
    return _instance;
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      // TODO: Call GET /api/users/me
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    required String name,
    String? photoUrl,
    String? language,
    String? preferredPaymentMethod,
  }) async {
    try {
      // TODO: Call PUT /api/users/profile
      throw UnimplementedError();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto(String filePath) async {
    try {
      // TODO: Upload to Azure Blob Storage with SAS token
      throw UnimplementedError();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user trip history
  Future<List<Map<String, dynamic>>> getTripHistory({
    String? period = 'all', // all, week, month
    String? paymentMethod, // wave, orange_money
  }) async {
    try {
      // TODO: Call GET /api/users/trips?period=&method=
      throw UnimplementedError();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      // TODO: Call GET /api/users/stats
      return {
        'total_trips': 0,
        'total_spent_fcfa': 0,
        'average_rating': 0.0,
        'member_since': DateTime.now(),
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      // TODO: Call DELETE /api/users/account
      throw UnimplementedError();
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } catch (e) {
      rethrow;
    }
  }
}

