import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/providers/trip_providers.dart';

/// ÉCRAN G — RECHERCHE CHAUFFEUR
/// Lottie animation
/// Cercle rayon Mapbox animé
/// Si aucun chauffeur 5min → annulation + remboursement
/// Bouton "Annuler" → remboursement Wave immédiat
class DriverSearchPage extends ConsumerStatefulWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final int estimatedPrice;

  const DriverSearchPage({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedPrice,
  });

  @override
  ConsumerState<DriverSearchPage> createState() => _DriverSearchPageState();
}

class _DriverSearchPageState extends ConsumerState<DriverSearchPage>
    with TickerProviderStateMixin {
  late AnimationController _radiusAnimationController;
  late AnimationController _pulseAnimationController;
  int _secondsRemaining = 300; // 5 minutes
  bool _driverFound = false;

  @override
  void initState() {
    super.initState();

    // Radius animation
    _radiusAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Pulse animation
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Start countdown
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0 && !_driverFound) {
        setState(() {
          _secondsRemaining--;
        });
        _startCountdown();
      } else if (_secondsRemaining == 0 && !_driverFound) {
        _handleNoDriverFound();
      }
    });
  }

  void _handleNoDriverFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Aucun chauffeur disponible. Remboursement en cours...'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 3),
      ),
    );

    // TODO: Implement auto-refund
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/map');
      }
    });
  }

  @override
  void dispose() {
    _radiusAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(availableDriversProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldCancel = await _showCancelConfirmation(context) ?? false;
        if (shouldCancel && mounted) {
          context.go('/map');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Fond carte placeholder
            Container(
              color: AppColors.background,
              child: const Center(
                child: Icon(Icons.map_outlined, size: 120, color: AppColors.textHint),
              ),
            ),

            // Content overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App Bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recherche de chauffeur',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showCancelConfirmation(context);
                            },
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center content: Animation + Timer
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pulsing circle animation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer radius circle (animated)
                          ScaleTransition(
                            scale: _radiusAnimationController
                                .drive(Tween(begin: 0.8, end: 1.2)),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryWithOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Inner circle with lottie
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryWithOpacity(0.1),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.two_wheeler,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Status text
                      Text(
                        'Nous cherchons un chauffeur...',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Timer
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.warningWithOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                            color: AppColors.warning,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Annulation automatique après 5 minutes',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                // Bottom: Cancel button
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          _showCancelConfirmation(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.danger,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'ANNULER',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCancelConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Annuler la réservation ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Votre paiement de ${widget.estimatedPrice} FCFA sera remboursé.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Continuer la recherche',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement refund
              Navigator.pop(context, true);
              context.go('/map');
            },
            child: Text(
              'Annuler & Rembourser',
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

