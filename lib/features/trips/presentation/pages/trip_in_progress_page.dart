import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/services/api_client.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';
import 'package:go_router/go_router.dart';

/// ECRAN I - COURSE EN COURS
class TripInProgressPage extends ConsumerStatefulWidget {
  final Trip trip;
  final double driverLat;
  final double driverLng;

  const TripInProgressPage({
    super.key,
    required this.trip,
    required this.driverLat,
    required this.driverLng,
  });

  @override
  ConsumerState<TripInProgressPage> createState() =>
      _TripInProgressPageState();
}

class _TripInProgressPageState extends ConsumerState<TripInProgressPage> {
  final SignalRService _signalRService = SignalRService();

  late Trip _trip;
  late double _distanceTraveled;
  late double _estimatedDistance;
  late double _progressPercentage;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _distanceTraveled = _trip.actualDistanceKm ?? 0;
    _estimatedDistance = _trip.estimatedDistanceKm ?? 1;
    _calculateProgress();

    _signalRService.connect();
    if (_trip.driverId != null) {
      _signalRService.onDriverLocationUpdate(
        driverId: _trip.driverId,
        callback: _handleDriverLocation,
      );
    }
    _pollTripStatus();
  }

  @override
  void dispose() {
    _signalRService.clearPassengerListeners();
    super.dispose();
  }

  void _handleDriverLocation(Driver driver) {
    if (!mounted) {
      return;
    }

    setState(() {
      final estimated = _trip.estimatedDistanceKm ?? _estimatedDistance;
      _distanceTraveled = (_distanceTraveled + 0.15).clamp(0, estimated);
      _estimatedDistance = estimated;
      _calculateProgress();
    });
  }

  void _calculateProgress() {
    final safeEstimatedDistance = _estimatedDistance <= 0 ? 1 : _estimatedDistance;
    _progressPercentage =
        ((_distanceTraveled / safeEstimatedDistance) * 100).clamp(0, 100);
  }

  Future<void> _pollTripStatus() async {
    if (!mounted) {
      return;
    }

    try {
      final refreshedTrip = await ApiClient().getTrip(_trip.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _trip = refreshedTrip;
        _distanceTraveled =
            refreshedTrip.actualDistanceKm ?? _distanceTraveled;
        _estimatedDistance =
            refreshedTrip.estimatedDistanceKm ?? _estimatedDistance;
        _calculateProgress();
      });

      if (refreshedTrip.status == TripStatus.driverConfirmed) {
        context.go('/arrival-confirmation', extra: {'trip': refreshedTrip});
        return;
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    Future.delayed(const Duration(seconds: 4), _pollTripStatus);
  }

  @override
  Widget build(BuildContext context) {
    final displayedPrice = _trip.actualPriceFcfa ?? _trip.estimatedPriceFcfa ?? 1750;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              color: AppColors.background,
              child: const Center(
                child: Icon(
                  Icons.alt_route,
                  size: 120,
                  color: AppColors.textHint,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flag,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _trip.dropoffAddress ?? 'Destination',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prix estimé',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '~$displayedPrice FCFA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(trajet réel)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.successWithOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Paiement sécurisé',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            '${_progressPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressPercentage / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.primaryWithOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.warningWithOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parcouru',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_distanceTraveled.toStringAsFixed(1)} km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Restant',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_estimatedDistance - _distanceTraveled).clamp(0, 999).toStringAsFixed(1)} km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _callSOS,
                          icon: const Icon(Icons.emergency),
                          label: const Text('SOS - APPELER AIDE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callSOS() async {
    final launchUri = Uri(scheme: 'tel', path: '17');
    await launchUrl(launchUri);
  }
}
