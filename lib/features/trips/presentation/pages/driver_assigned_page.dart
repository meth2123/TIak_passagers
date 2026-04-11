import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/driver.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/services/api_client.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';

/// ECRAN H - CHAUFFEUR ASSIGNE
class DriverAssignedPage extends ConsumerStatefulWidget {
  final String tripId;
  final Driver driver;
  final String destination;
  final int estimatedPrice;

  const DriverAssignedPage({
    super.key,
    required this.tripId,
    required this.driver,
    required this.destination,
    required this.estimatedPrice,
  });

  @override
  ConsumerState<DriverAssignedPage> createState() => _DriverAssignedPageState();
}

class _DriverAssignedPageState extends ConsumerState<DriverAssignedPage> {
  final SignalRService _signalRService = SignalRService();

  late Driver _driver;
  int _etaMinutes = 3;
  final double _distanceKm = 2.5;
  bool _isCancelling = false;
  bool _arrivalNoticeShown = false;

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;

    _signalRService.connect();
    _signalRService.onDriverLocationUpdate(
      driverId: _driver.id,
      callback: (driver) {
        if (!mounted) {
          return;
        }
        setState(() {
          _driver = driver;
        });
      },
    );
    _signalRService.onEtaUpdated(
      callback: (etaMinutes, driverLat, driverLng) {
        if (!mounted) {
          return;
        }
        setState(() {
          _etaMinutes = etaMinutes;
          _driver = Driver(
            id: _driver.id,
            userId: _driver.userId,
            name: _driver.name,
            phoneNumber: _driver.phoneNumber,
            photoUrl: _driver.photoUrl,
            motoModel: _driver.motoModel,
            plateNumber: _driver.plateNumber,
            rating: _driver.rating,
            totalTrips: _driver.totalTrips,
            status: _driver.status,
            verified: _driver.verified,
            location: LatLng(driverLat, driverLng),
            heading: _driver.heading,
            speed: _driver.speed,
            isAvailable: _driver.isAvailable,
            updatedAt: _driver.updatedAt,
          );
        });
      },
    );
    _signalRService.onDriverArrived(
      callback: () {
        if (!mounted || _arrivalNoticeShown) {
          return;
        }
        _arrivalNoticeShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre chauffeur est arrivé.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
    _signalRService.onTripStatusUpdate(
      tripId: widget.tripId,
      callback: (trip) async {
        if (!mounted) {
          return;
        }
        if (trip.status == TripStatus.inProgress) {
          final fullTrip = await ApiClient().getTrip(widget.tripId);
          if (!mounted) {
            return;
          }
          context.go('/trip-in-progress', extra: {'trip': fullTrip});
        }
      },
    );

    _pollTripStatus();
  }

  @override
  void dispose() {
    _signalRService.clearPassengerListeners();
    super.dispose();
  }

  Future<void> _pollTripStatus() async {
    if (!mounted || widget.tripId.isEmpty) {
      return;
    }

    try {
      final trip = await ApiClient().getTrip(widget.tripId);
      if (!mounted) {
        return;
      }

      if (trip.status == TripStatus.inProgress) {
        context.go('/trip-in-progress', extra: {'trip': trip});
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppColors.background,
            child: Center(
              child: Opacity(
                opacity: 0.72,
                child: Image.asset(
                  AppConstants.deliveryHeroAsset,
                  width: 250,
                  fit: BoxFit.cover,
                ),
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primaryWithOpacity(0.1),
                            backgroundImage: _driver.photoUrl != null
                                ? NetworkImage(_driver.photoUrl!)
                                : null,
                            child: _driver.photoUrl == null
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Image.asset(
                                      AppConstants.scooterFrameAsset,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _driver.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.successWithOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_driver.rating ?? 5}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_driver.motoModel ?? 'Moto'} • ${_driver.plateNumber ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.labelMedium
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Arrivée',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '~$_etaMinutes min',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Destination',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.destination,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.route,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Distance',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_distanceKm.toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
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
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _driver.phoneNumber == null
                            ? null
                            : () => _callDriver(_driver.phoneNumber!),
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling
                            ? null
                            : () => _showCancelConfirmation(context),
                        icon: const Icon(Icons.close),
                        label: Text(
                          _isCancelling ? 'ANNULATION...' : 'ANNULER',
                        ),
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

  Future<void> _callDriver(String phoneNumber) async {
    final launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Annuler cette réservation ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Des frais d\'annulation peuvent s\'appliquer si le chauffeur est déjà arrivé.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Continuer',
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

    if (shouldCancel != true || !mounted || _isCancelling) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await ApiClient().cancelTrip(widget.tripId);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'annuler la course maintenant.'),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) {
        this.context.go('/map');
      }
    }
  }
}
