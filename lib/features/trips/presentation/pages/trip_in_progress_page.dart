import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:url_launcher/url_launcher.dart';

/// ÉCRAN I — COURSE EN COURS
/// Polyline Mapbox
/// Position chauffeur live (SignalR)
/// Prix affiché : "~1 750 FCFA (trajet réel)"
/// Badge vert : "Paiement sécurisé ✓"
/// Bouton SOS → tel:17
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
  double _distanceTraveled = 3.5; // km
  double _estimatedDistance = 8.2; // km
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  void _calculateProgress() {
    setState(() {
      _progressPercentage = (_distanceTraveled / _estimatedDistance) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estimatedPrice = widget.trip.estimatedPriceFcfa ?? 1750;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        body: Stack(
          children: [
            // Fond carte placeholder
            Container(
              color: AppColors.background,
              child: const Center(
                child: Icon(Icons.alt_route, size: 120, color: AppColors.textHint),
              ),
            ),

            // Top Info Card
            SafeArea(
              child: Positioned(
                top: 16,
                left: 16,
                right: 16,
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
                        // Destination
                        Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.trip.dropoffAddress ?? 'Destination',
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

                        // Price badge + Secure payment badge
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prix estimé',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '~$estimatedPrice FCFA',
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
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),

                            // Secure payment badge
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.successWithOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Paiement',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'sécurisé ✓',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight:
                                              FontWeight.w600,
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

            // Bottom Progress Info
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
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                            borderRadius:
                                BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressPercentage / 100,
                              minHeight: 8,
                              backgroundColor: AppColors
                                  .primaryWithOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Distance info
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.warningWithOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parcouru',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            AppColors.textSecondary,
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Restant',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_estimatedDistance - _distanceTraveled).toStringAsFixed(1)} km',
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

                      // SOS Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _callSOS();
                          },
                          icon: const Icon(Icons.emergency),
                          label: const Text('SOS - APPELER AIDE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
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

  void _callSOS() {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '17', // Police numéro d'urgence Sénégal
    );
    launchUrl(launchUri);
  }
}

