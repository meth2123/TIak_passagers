import 'package:flutter/material.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/price_estimate.dart';

class PriceDisplayWidget extends StatelessWidget {
  final PriceEstimate? priceEstimate;
  final VoidCallback onReservePressed;

  const PriceDisplayWidget({
    super.key,
    required this.priceEstimate,
    required this.onReservePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (priceEstimate == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final breakdown = priceEstimate!.breakdown;
    final multiplierReason = breakdown?['multiplier_reason'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prix principal (gros, centré)
                  Text(
                    '${priceEstimate!.estimatedPriceFcfa} FCFA',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.primary,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                  ),

                  // Fourchette si incertitude
                  if (priceEstimate!.priceMinFcfa != null &&
                      priceEstimate!.priceMaxFcfa != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${priceEstimate!.priceMinFcfa} – ${priceEstimate!.priceMaxFcfa} FCFA',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Distance et durée
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoColumn(
                        icon: Icons.location_on,
                        label: 'Distance',
                        value:
                            '${priceEstimate!.distanceKm.toStringAsFixed(1)} km',
                      ),
                      _InfoColumn(
                        icon: Icons.timer,
                        label: 'Durée',
                        value: '~${priceEstimate!.durationMin} min',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Badges (heure pointe, pluie)
                  if (multiplierReason != null)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.warningWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        multiplierReason,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Mention légale
                  Text(
                    'Prix basé sur le trajet réel',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton RÉSERVER
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onReservePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'RÉSERVER',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

