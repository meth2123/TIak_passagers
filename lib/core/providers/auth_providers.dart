import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/models/user.dart';

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);

  void setUser(User user) {
    state = user;
  }

  void updateUser(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final otpSendingProvider = StateProvider<bool>((ref) => false);
final otpCodeProvider = StateProvider<String>((ref) => '');
final phoneNumberProvider = StateProvider<String>((ref) => '+221');
final otpVerificationErrorProvider = StateProvider<String?>((ref) => null);

