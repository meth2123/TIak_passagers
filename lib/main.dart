import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/services/auth_service.dart';
import 'package:tiak_passenger/core/services/location_service.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';
import 'package:tiak_passenger/features/auth/presentation/pages/splash_page.dart';
import 'package:tiak_passenger/features/auth/presentation/pages/onboarding_page.dart';
import 'package:tiak_passenger/features/auth/presentation/pages/auth_page.dart';
import 'package:tiak_passenger/features/auth/presentation/pages/profile_creation_page.dart';
import 'package:tiak_passenger/features/auth/presentation/pages/web_home_page.dart';
import 'package:tiak_passenger/features/map/presentation/pages/home_map_page.dart';
import 'package:tiak_passenger/features/payments/presentation/pages/payment_method_page.dart';
import 'package:tiak_passenger/features/payments/presentation/pages/payment_processing_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/driver_search_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/driver_assigned_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/trip_in_progress_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/arrival_confirmation_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/trip_summary_page.dart';
import 'package:tiak_passenger/features/profile/presentation/pages/rating_page.dart';
import 'package:tiak_passenger/features/profile/presentation/pages/profile_page.dart';
import 'package:tiak_passenger/features/profile/presentation/pages/settings_page.dart';
import 'package:tiak_passenger/features/trips/presentation/pages/trips_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (ne bloque pas le boot local si la config n'est pas encore branchée)
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  try {
    await AuthService().initialize();
  } catch (_) {}

  if (!kIsWeb) {
    try {
      await LocationService().initialize();
    } catch (_) {}

    try {
      await SignalRService().initialize();
    } catch (_) {}
  }

  runApp(const ProviderScope(child: TiakPassengerApp()));
}

class TiakPassengerApp extends ConsumerStatefulWidget {
  const TiakPassengerApp({super.key});

  @override
  ConsumerState<TiakPassengerApp> createState() => _TiakPassengerAppState();
}

class _TiakPassengerAppState extends ConsumerState<TiakPassengerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    // For web platform, show a simple home page
    if (kIsWeb) {
      return GoRouter(
        initialLocation: '/web-home',
        routes: [
          GoRoute(
            path: '/web-home',
            builder: (context, state) => const WebHomePage(),
          ),
        ],
      );
    }

    final mockDriver = Driver(
      id: 'd-1',
      userId: 'u-d-1',
      name: 'Moussa D.',
      motoModel: 'Honda Wave 110',
      plateNumber: 'DK-1234-AB',
      rating: 4.9,
      status: DriverStatus.active,
      isAvailable: true,
    );

    final mockTrip = Trip(
      id: 'TR-${DateTime.now().millisecondsSinceEpoch}',
      passengerId: 'u-p-1',
      pickupLocation: const LatLng(14.6928, -17.0369),
      dropoffLocation: const LatLng(14.7416, -17.5104),
      pickupAddress: 'Plateau',
      dropoffAddress: 'Almadies',
      estimatedPriceFcfa: 1750,
      estimatedDistanceKm: 8.2,
      estimatedDurationMin: 22,
      status: TripStatus.inProgress,
      paymentMethod: PaymentMethod.wave,
      createdAt: DateTime.now(),
    );

    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
        GoRoute(
          path: '/profile-creation',
          builder: (context, state) => const ProfileCreationPage(),
        ),
        GoRoute(path: '/map', builder: (context, state) => const MapPage()),
        GoRoute(
          path: '/payment-method',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentMethodPage(
              estimatedPrice: extra?['estimatedPrice'] ?? 1750,
              destination: extra?['destination'] ?? 'Destination',
              pickupAddress: extra?['pickupAddress'] ?? 'Depart',
              dropoffAddress: extra?['dropoffAddress'] ?? 'Destination',
              pickupLat: extra?['pickupLat'] as double?,
              pickupLng: extra?['pickupLng'] as double?,
              dropoffLat: extra?['dropoffLat'] as double?,
              dropoffLng: extra?['dropoffLng'] as double?,
            );
          },
        ),
        GoRoute(
          path: '/payment-processing',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentProcessingPage(
              tripId: extra?['tripId'] as String? ?? '',
              paymentMethod: (extra?['paymentMethod'] as PaymentMethod?) ??
                  PaymentMethod.wave,
              amount: extra?['amount'] as int? ?? 0,
              deepLink: extra?['deepLink'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/driver-search',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return DriverSearchPage(
              pickupAddress: extra?['pickupAddress'] ?? 'Départ',
              dropoffAddress: extra?['dropoffAddress'] ?? 'Arrivée',
              estimatedPrice: extra?['estimatedPrice'] ?? 1750,
            );
          },
        ),
        GoRoute(
          path: '/driver-assigned',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return DriverAssignedPage(
              driver: (extra?['driver'] as Driver?) ?? mockDriver,
              destination: extra?['destination'] ?? 'Destination',
              estimatedPrice: extra?['estimatedPrice'] ?? 1750,
            );
          },
        ),
        GoRoute(
          path: '/trip-in-progress',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return TripInProgressPage(
              trip: (extra?['trip'] as Trip?) ?? mockTrip,
              driverLat: extra?['driverLat'] ?? 14.6928,
              driverLng: extra?['driverLng'] ?? -17.0369,
            );
          },
        ),
        GoRoute(
          path: '/arrival-confirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ArrivalConfirmationPage(
              trip: (extra?['trip'] as Trip?) ?? mockTrip,
            );
          },
        ),
        GoRoute(
          path: '/trip-summary',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return TripSummaryPage(trip: (extra?['trip'] as Trip?) ?? mockTrip);
          },
        ),
        GoRoute(
          path: '/rating',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return RatingPage(
              driver: (extra?['driver'] as Driver?) ?? mockDriver,
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/trips-history',
          builder: (context, state) => const TripsHistoryPage(),
        ),
      ],
      redirect: (context, state) {
        final authService = ref.read(authServiceProvider);
        final isAuth = authService.isAuthenticated;
        final isOnboardingDone = authService.isOnboardingCompleted;
        final user = authService.getUserData();
        final needsProfileCompletion =
            isAuth && ((user?.name.trim().isEmpty ?? true) || user?.name == 'Utilisateur');
        final path = state.matchedLocation;

        if (!isAuth &&
            path != '/splash' &&
            path != '/auth' &&
            path != '/onboarding') {
          return '/auth';
        }

        if (isAuth && !isOnboardingDone && path != '/onboarding') {
          return '/onboarding';
        }

        if (isAuth && isOnboardingDone && needsProfileCompletion && path != '/profile-creation') {
          return '/profile-creation';
        }

        if (isAuth && (path == '/auth' || path == '/splash')) {
          return '/map';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
