import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/price_estimate.dart';

/// Trip state management
class TripNotifier extends StateNotifier<Trip?> {
  TripNotifier() : super(null);

  void setTrip(Trip trip) {
    state = trip;
  }

  void updateTripStatus(TripStatus status) {
    if (state != null) {
      state = state!.copyWith(status: status);
    }
  }

  void clearTrip() {
    state = null;
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, Trip?>((ref) {
  return TripNotifier();
});

/// Available drivers state
class DriversNotifier extends StateNotifier<List<Driver>> {
  DriversNotifier() : super([]);

  void setDrivers(List<Driver> drivers) {
    state = drivers;
  }

  void updateDriver(Driver driver) {
    state = state
        .map((d) => d.id == driver.id ? driver : d)
        .toList();
  }

  void clearDrivers() {
    state = [];
  }
}

final availableDriversProvider =
    StateNotifierProvider<DriversNotifier, List<Driver>>((ref) {
  return DriversNotifier();
});

/// Selected driver state
final selectedDriverProvider = StateProvider<Driver?>((ref) => null);

/// Price estimate state
final priceEstimateProvider = StateProvider<PriceEstimate?>((ref) => null);

/// Loading states
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Payment method selection
final selectedPaymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.wave);

/// Trip confirmation states
final isWaitingConfirmationProvider = StateProvider<bool>((ref) => false);
final confirmationTimerProvider = StateProvider<int>((ref) => 0);

