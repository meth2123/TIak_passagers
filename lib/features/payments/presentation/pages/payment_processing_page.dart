import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/services/signalr_service.dart';

/// ÉCRAN F — PAIEMENT WAVE/OM
/// Loader "Ouverture Wave..."
/// url_launcher deep link → app Wave/OM
/// Attente webhook (SignalR event en background)
/// Écran retour : "Paiement confirmé ✓ 1 750 FCFA"
class PaymentProcessingPage extends ConsumerStatefulWidget {
  final String tripId;
  final PaymentMethod paymentMethod;
  final int amount;
  final String? deepLink;
  final String pickupAddress;
  final String dropoffAddress;

  const PaymentProcessingPage({
    super.key,
    required this.tripId,
    required this.paymentMethod,
    required this.amount,
    this.deepLink,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  ConsumerState<PaymentProcessingPage> createState() =>
      _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends ConsumerState<PaymentProcessingPage> {
  late String _paymentStatus = 'opening';
  bool _isConfirming = false;
  final SignalRService _signalRService = SignalRService();

  @override
  void initState() {
    super.initState();
    _signalRService.connect();
    _signalRService.onPaymentStatusUpdate(
      tripId: widget.tripId,
      callback: (tripId, status) async {
        if (!mounted) {
          return;
        }

        setState(() => _paymentStatus = 'confirmed');
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) {
          return;
        }
        _goToDriverSearch();
      },
    );
    _initiatePayment();
  }

  @override
  void dispose() {
    _signalRService.clearPassengerListeners();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    try {
      setState(() => _paymentStatus = 'opening');

      final deepLink =
          widget.deepLink ??
          (widget.paymentMethod == PaymentMethod.wave
              ? 'wave://pay?amount=${widget.amount}&ref=${widget.tripId}'
              : 'om://pay?amount=${widget.amount}&ref=${widget.tripId}');

      // Launch payment app
      if (await canLaunchUrl(Uri.parse(deepLink))) {
        await launchUrl(
          Uri.parse(deepLink),
          mode: LaunchMode.externalApplication,
        );
        setState(() => _paymentStatus = 'waiting');
      } else {
        setState(() => _paymentStatus = 'error');
      }
    } catch (e) {
      setState(() => _paymentStatus = 'error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmPaymentAndContinue() async {
    if (_isConfirming) {
      return;
    }

    setState(() => _isConfirming = true);
    setState(() => _paymentStatus = 'confirmed');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) {
      return;
    }
    _goToDriverSearch();
  }

  void _goToDriverSearch() {
    context.go(
      '/driver-search',
      extra: {
        'tripId': widget.tripId,
        'pickupAddress': widget.pickupAddress,
        'dropoffAddress': widget.dropoffAddress,
        'estimatedPrice': widget.amount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated payment icon
                if (_paymentStatus == 'opening' || _paymentStatus == 'waiting')
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryWithOpacity(0.1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              AppConstants.scooterFrameAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (_paymentStatus == 'confirmed')
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.successWithOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: AppColors.success,
                    ),
                  ),

                const SizedBox(height: 32),

                // Status text
                if (_paymentStatus == 'opening')
                  Column(
                    children: [
                      Text(
                        'Ouverture ${widget.paymentMethod == PaymentMethod.wave ? 'Wave' : 'Orange Money'}...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez confirmer le paiement dans l\'application',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CircularProgressIndicator(color: AppColors.primary),
                    ],
                  ),
                if (_paymentStatus == 'waiting')
                  Column(
                    children: [
                      Text(
                        'Paiement en attente...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Montant: ${widget.amount} FCFA',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isConfirming
                              ? null
                              : _confirmPaymentAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isConfirming
                                ? 'VERIFICATION...'
                                : 'J\'AI CONFIRME LE PAIEMENT',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_paymentStatus == 'confirmed')
                  Column(
                    children: [
                      Text(
                        'Paiement confirmé ✓',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.amount} FCFA',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(color: AppColors.success, fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recherche de chauffeur...',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                if (_paymentStatus == 'error')
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de paiement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _initiatePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('RÉESSAYER'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
