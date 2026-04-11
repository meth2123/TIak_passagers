import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/providers/trip_providers.dart';
import 'package:tiak_passenger/core/services/api_client.dart';

/// ECRAN E - SELECTION METHODE PAIEMENT
class PaymentMethodPage extends ConsumerStatefulWidget {
  final int estimatedPrice;
  final String destination;
  final String pickupAddress;
  final String dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  const PaymentMethodPage({
    super.key,
    required this.estimatedPrice,
    required this.destination,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Methode de paiement',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant a payer',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.estimatedPrice} FCFA',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 28,
                              ),
                        ),
                        Flexible(
                          child: Text(
                            widget.destination,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Choisir une methode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _PaymentMethodTile(
                method: PaymentMethod.wave,
                isSelected: selectedMethod == PaymentMethod.wave,
                methodName: 'Wave',
                description: 'Ouvre l\'app Wave · Paiement securise',
                onTap: () {
                  ref.read(selectedPaymentMethodProvider.notifier).state =
                      PaymentMethod.wave;
                },
              ),
              const SizedBox(height: 12),
              _PaymentMethodTile(
                method: PaymentMethod.orangeMoney,
                isSelected: selectedMethod == PaymentMethod.orangeMoney,
                methodName: 'Orange Money',
                description: 'Ouvre l\'app Orange Money · Securise',
                onTap: () {
                  ref.read(selectedPaymentMethodProvider.notifier).state =
                      PaymentMethod.orangeMoney;
                },
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.dangerWithOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucun cash accepte',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tiak-Tiak accepte uniquement Wave et Orange Money pour garantir la securite de tous.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePaymentInitiation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isProcessing ? 'TRAITEMENT...' : 'PAYER ET RESERVER',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentInitiation() async {
    final selectedMethod = ref.read(selectedPaymentMethodProvider);
    final methodApi = selectedMethod == PaymentMethod.wave
        ? 'wave'
        : 'orange_money';

    setState(() => _isProcessing = true);

    try {
      if (widget.pickupLat == null ||
          widget.pickupLng == null ||
          widget.dropoffLat == null ||
          widget.dropoffLng == null) {
        throw Exception('Coordonnees manquantes pour creer la course');
      }

      final tripResponse = await ApiClient().requestTrip(
        pickup: LatLng(widget.pickupLat!, widget.pickupLng!),
        dropoff: LatLng(widget.dropoffLat!, widget.dropoffLng!),
        pickupAddress: widget.pickupAddress,
        dropoffAddress: widget.dropoffAddress,
        paymentMethod: methodApi,
      );

      final tripRef = tripResponse['trip_id'] as String;
      final response = await ApiClient().initiatePayment(
        tripId: tripRef,
        method: methodApi,
      );

      if (!mounted) return;

      context.push('/payment-processing',
        extra: {
          'tripId': tripRef,
          'paymentMethod': selectedMethod,
          'amount': widget.estimatedPrice,
          'deepLink': response['deep_link'] as String?,
          'pickupAddress': widget.pickupAddress,
          'dropoffAddress': widget.dropoffAddress,
        },
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement indisponible. Veuillez reessayer pour continuer.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final String methodName;
  final String description;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.methodName,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryWithOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    methodName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
