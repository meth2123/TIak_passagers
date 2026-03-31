import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// ÉCRAN H — CHAUFFEUR ASSIGNÉ
/// Photo ronde + nom + note + moto + plaque
/// ETA temps réel (SignalR)
/// Position Mapbox
/// [Appeler] [Annuler]
class DriverAssignedPage extends ConsumerStatefulWidget {
  final Driver driver;
  final String destination;
  final int estimatedPrice;

  const DriverAssignedPage({
    super.key,
    required this.driver,
    required this.destination,
    required this.estimatedPrice,
  });

  @override
  ConsumerState<DriverAssignedPage> createState() =>
      _DriverAssignedPageState();
}

class _DriverAssignedPageState extends ConsumerState<DriverAssignedPage> {
  int _etaMinutes = 3; // Mock ETA, update via SignalR

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond carte placeholder (Mapbox branchable)
          Container(
            color: AppColors.background,
            child: const Center(
              child: Icon(Icons.navigation, size: 96, color: AppColors.textHint),
            ),
          ),

          // Top: Driver Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Driver Photo + Name + Rating
                      Row(
                        children: [
                          // Photo ronde
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primaryWithOpacity(0.1),
                            backgroundImage: widget.driver.photoUrl != null
                                ? NetworkImage(widget.driver.photoUrl!)
                                : null,
                            child: widget.driver.photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 16),

                          // Name + Rating + Moto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.driver.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors
                                            .successWithOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 16,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.driver.rating}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.driver.motoModel} • ${widget.driver.plateNumber}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      // ETA + Distance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Arrivée',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '~${_etaMinutes} min',
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
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Distance',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '2.5 km',
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom: Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: Colors.white.withValues(alpha: 0.96),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _callDriver('+221770001122');
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('APPELER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cancel Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showCancelConfirmation(context);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('ANNULER'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.danger,
                            width: 2,
                          ),
                          foregroundColor: AppColors.danger,
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
    );
  }

  void _callDriver(String phoneNumber) {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    launchUrl(launchUri);
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Annuler cette réservation ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Frais de ${widget.estimatedPrice ~/ 3} FCFA seront retenus car le chauffeur s\'approche.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continuer',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement late cancellation
              Navigator.pop(context);
              context.go('/map');
            },
            child: Text(
              'Annuler & Payer les frais',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

