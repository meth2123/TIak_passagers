import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/price_estimate.dart';
import 'package:tiak_passenger/core/providers/trip_providers.dart';
import 'package:tiak_passenger/core/services/api_client.dart';
import 'package:tiak_passenger/core/services/location_service.dart';
import 'package:tiak_passenger/features/shared/widgets/price_display_widget.dart';
import 'package:tiak_passenger/features/shared/widgets/bottom_sheet_destination.dart';

/// ÉCRAN D — CARTE PRINCIPALE (Mapbox)
/// - Style streets-v12, accents #FF6B35
/// - Markers chauffeurs dispo (icône moto custom)
/// - Mise à jour SignalR toutes les 3s
/// - Barre recherche destination (Mapbox Search API)
/// - Départ : géocodage inverse Mapbox
/// - Affichage prix dynamique AVANT sélection destination
/// - Affichage prix APRÈS destination saisie
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = 'Plateau, Dakar';
  String _dropoffAddress = 'Almadies';
  final TextEditingController _destinationController = TextEditingController();

  static const LatLng _defaultDakarLocation = LatLng(14.6928, -17.4467);

  @override
  void initState() {
    super.initState();
    _initializePickup();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceEstimate = ref.watch(priceEstimateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Placeholder carte (Mapbox à brancher ensuite)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.12),
                  Colors.blue.withValues(alpha: 0.10),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(Icons.map, size: 120, color: AppColors.textHint),
            ),
          ),

          // Departure & Destination Search Bar (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Current location / Pickup
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Départ',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              _pickupLocation == null
                                  ? 'Détection localisation...'
                                  : _pickupAddress,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Destination Search
                GestureDetector(
                  onTap: () {
                    _showDestinationBottomSheet(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.flag, color: Colors.red, size: 24),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              Text(
                                _dropoffLocation == null
                                    ? 'Où allez-vous ?'
                                    : _dropoffAddress,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 170,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/profile'),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Price Display Widget (Bottom)
          if (_dropoffLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: PriceDisplayWidget(
                priceEstimate: priceEstimate,
                onReservePressed: _handleReservePressed,
              ),
            )
          else
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'À partir de',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '500 FCFA',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDestinationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DestinationBottomSheet(
        onLocationSelected: (location, address) {
          setState(() {
            _dropoffLocation = location;
            _dropoffAddress = address;
          });
          // Fetch price estimate
          _fetchPriceEstimate();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _fetchPriceEstimate() async {
    final pickup = _pickupLocation;
    final dropoff = _dropoffLocation;
    if (pickup == null || dropoff == null) {
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final estimate = await ApiClient().estimatePrice(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
      );
      ref.read(priceEstimateProvider.notifier).state = estimate;
    } catch (_) {
      final fallbackEstimate = _buildFallbackEstimate(pickup, dropoff);
      ref.read(priceEstimateProvider.notifier).state = fallbackEstimate;
      ref.read(errorMessageProvider.notifier).state =
          'Estimation locale utilisee temporairement.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connexion indisponible, estimation locale utilisee.',
            ),
          ),
        );
      }
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _handleReservePressed() {
    final pickup = _pickupLocation;
    final estimate = ref.read(priceEstimateProvider);

    if (_dropoffLocation == null || estimate == null || pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionnez une destination valide.')),
      );
      return;
    }

    context.push(
      '/payment-method',
      extra: {
        'estimatedPrice': estimate.estimatedPriceFcfa,
        'destination': _dropoffAddress,
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'pickupLat': pickup.latitude,
        'pickupLng': pickup.longitude,
        'dropoffLat': _dropoffLocation!.latitude,
        'dropoffLng': _dropoffLocation!.longitude,
      },
    );
  }

  Future<void> _initializePickup() async {
    final location = await LocationService().getCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _pickupLocation = location ?? _defaultDakarLocation;
      _pickupAddress = location == null
          ? 'Plateau, Dakar'
          : 'Position actuelle';
    });
  }

  PriceEstimate _buildFallbackEstimate(LatLng pickup, LatLng dropoff) {
    final distanceKm = LocationService().calculateDistance(pickup, dropoff);
    final rawPrice = 300 + (180 * distanceKm);
    final roundedPrice = ((rawPrice / 50).ceil() * 50).toInt();
    final estimatedPrice = distanceKm < 2 ? 500 : roundedPrice;
    final minPrice = (estimatedPrice - 100).clamp(500, 999999).toInt();
    final maxPrice = estimatedPrice + 100;
    final durationMin = (distanceKm * 2.7).round().clamp(5, 120);

    return PriceEstimate(
      estimatedPriceFcfa: estimatedPrice,
      priceMinFcfa: minPrice,
      priceMaxFcfa: maxPrice,
      distanceKm: distanceKm,
      durationMin: durationMin,
      breakdown: {
        'base_fare': 300,
        'distance_cost': (180 * distanceKm).round(),
        'subtotal': rawPrice.round(),
        'multiplier': 1.0,
        'multiplier_reason': null,
        'rounded_to': estimatedPrice,
      },
      surgeActive: false,
      surgeReason: null,
    );
  }
}
