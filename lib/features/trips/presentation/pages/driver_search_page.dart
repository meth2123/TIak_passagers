import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/providers/trip_providers.dart';
import 'package:tiak_passenger/core/services/api_client.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';

/// ECRAN G - RECHERCHE CHAUFFEUR
class DriverSearchPage extends ConsumerStatefulWidget {
  final String tripId;
  final String pickupAddress;
  final String dropoffAddress;
  final int estimatedPrice;

  const DriverSearchPage({
    super.key,
    required this.tripId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedPrice,
  });

  @override
  ConsumerState<DriverSearchPage> createState() => _DriverSearchPageState();
}

class _DriverSearchPageState extends ConsumerState<DriverSearchPage>
    with TickerProviderStateMixin {
  late final AnimationController _radiusAnimationController;
  late final AnimationController _pulseAnimationController;
  final SignalRService _signalRService = SignalRService();

  int _secondsRemaining = 300;
  bool _driverFound = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();

    _radiusAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _signalRService.connect();
    _signalRService.onDriverFound(callback: _handleDriverFound);
    _startCountdown();
    _pollTripStatus();
  }

  @override
  void dispose() {
    _signalRService.clearPassengerListeners();
    _radiusAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _driverFound || _isCancelling) {
        return;
      }

      if (_secondsRemaining <= 0) {
        _handleNoDriverFound();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
      _startCountdown();
    });
  }

  Future<void> _pollTripStatus() async {
    if (!mounted || _driverFound || widget.tripId.isEmpty) {
      return;
    }

    try {
      final trip = await ApiClient().getTrip(widget.tripId);
      ref.read(tripProvider.notifier).setTrip(trip);

      if (!mounted || _driverFound) {
        return;
      }

      if (trip.status == TripStatus.inProgress) {
        context.go('/trip-in-progress', extra: {'trip': trip});
        return;
      }

      if (trip.status == TripStatus.driverConfirmed) {
        context.go('/arrival-confirmation', extra: {'trip': trip});
        return;
      }
    } catch (_) {}

    if (!mounted || _driverFound || _isCancelling) {
      return;
    }

    Future.delayed(const Duration(seconds: 4), _pollTripStatus);
  }

  void _handleDriverFound(Driver driver) {
    if (!mounted || _driverFound) {
      return;
    }

    setState(() {
      _driverFound = true;
    });

    ref.read(selectedDriverProvider.notifier).state = driver;

    context.go(
      '/driver-assigned',
      extra: {
        'tripId': widget.tripId,
        'driver': driver,
        'destination': widget.dropoffAddress,
        'estimatedPrice': widget.estimatedPrice,
      },
    );
  }

  Future<void> _handleNoDriverFound() async {
    await _cancelTrip(
      message: 'Aucun chauffeur disponible. Annulation en cours...',
    );
  }

  Future<void> _cancelTrip({String? message}) async {
    if (_isCancelling || widget.tripId.isEmpty) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await ApiClient().cancelTrip(widget.tripId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Course annulée. Le remboursement sera traité.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'annuler la course pour le moment.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        context.go('/map');
      }
    }
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
          await _cancelTrip();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              color: AppColors.background,
              child: Center(
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    AppConstants.deliveryHeroAsset,
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final shouldCancel =
                                  await _showCancelConfirmation(context) ??
                                  false;
                              if (shouldCancel && mounted) {
                                await _cancelTrip();
                              }
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
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _radiusAnimationController.drive(
                              Tween(begin: 0.8, end: 1.2),
                            ),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  AppConstants.scooterFrameAsset,
                                  width: 82,
                                  height: 82,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Nous cherchons un chauffeur...',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
                        onPressed: _isCancelling
                            ? null
                            : () async {
                                final shouldCancel =
                                    await _showCancelConfirmation(context) ??
                                    false;
                                if (shouldCancel && mounted) {
                                  await _cancelTrip();
                                }
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
                          _isCancelling ? 'ANNULATION...' : 'ANNULER',
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
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Annuler la réservation ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Votre paiement de ${widget.estimatedPrice} FCFA sera remboursé si la course n\'a pas démarré.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Continuer la recherche',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Annuler la course',
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
