import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/trip.dart';
import 'package:tiak_passenger/core/services/api_client.dart';

/// ÉCRAN J — CONFIRMATION ARRIVÉE
/// Notification push ou détection GPS auto
/// "Êtes-vous arrivé à [Almadies] ?"
/// [OUI, je suis arrivé] → libération Wave
/// [Signaler un problème] → litige
/// Timer auto-confirm 5min visible
class ArrivalConfirmationPage extends ConsumerStatefulWidget {
  final Trip trip;

  const ArrivalConfirmationPage({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<ArrivalConfirmationPage> createState() =>
      _ArrivalConfirmationPageState();
}

class _ArrivalConfirmationPageState extends ConsumerState<ArrivalConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  int _secondsRemaining = 300; // 5 minutes
  bool _confirmed = false;
  bool _disputed = false;

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      duration: const Duration(minutes: 5),
      vsync: this,
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0 && !_confirmed && !_disputed) {
        setState(() {
          _secondsRemaining--;
        });
        _startCountdown();
      } else if (_secondsRemaining == 0 && !_confirmed && !_disputed) {
        _handleAutoConfirm();
      }
    });
  }

  void _handleAutoConfirm() {
    _confirmArrival(auto: true);
  }

  Future<void> _confirmArrival({bool auto = false}) async {
    if (_confirmed) {
      return;
    }

    setState(() {
      _confirmed = true;
    });

    try {
      await ApiClient().confirmArrival(widget.trip.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auto ? 'Confirme automatiquement ✓' : 'Paiement libere ✓'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) {
        return;
      }

      context.go('/trip-summary', extra: {'trip': widget.trip});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _confirmed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Echec de confirmation. Reessayez.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.trip.dropoffAddress ?? 'destination';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Icon + Question
                Column(
                  children: [
                    const SizedBox(height: 40),

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successWithOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 60,
                        color: AppColors.success,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Êtes-vous arrivé ?',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'À $destination',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Middle: Timer
                Column(
                  children: [
                    Text(
                      'Confirmation automatique dans',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      value: _secondsRemaining / 300,
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor:
                          AppColors.primaryWithOpacity(0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(
                        color: AppColors.primary,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Bottom: Action Buttons
                Column(
                  children: [
                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _confirmed
                            ? null
                            : () => _confirmArrival(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confirmed
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _confirmed
                              ? 'CONFIRMÉ ✓'
                              : 'OUI, JE SUIS ARRIVÉ',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Report Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _confirmed
                            ? null
                            : () {
                                setState(() {
                                  _disputed = true;
                                });
                                _showDisputeBottomSheet();
                              },
                        icon: const Icon(Icons.report_problem),
                        label: const Text(
                            'SIGNALER UN PROBLÈME'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.warning,
                            width: 2,
                          ),
                          foregroundColor: AppColors.warning,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          disabledForegroundColor:
                              AppColors.textSecondary,
                        ),
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

  void _showDisputeBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => DelegateDisputeBottomSheet(
        onDisputeSubmitted: (reason) async {
          try {
            await ApiClient().disputeTrip(tripId: widget.trip.id, reason: reason);
            if (!mounted) {
              return;
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Litige signale. Admin reviendra vers vous sous 24h.'),
                backgroundColor: AppColors.warning,
              ),
            );
          } catch (_) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Echec envoi litige. Reessayez.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }
}

class DelegateDisputeBottomSheet extends StatefulWidget {
  final Future<void> Function(String reason) onDisputeSubmitted;

  const DelegateDisputeBottomSheet({
    super.key,
    required this.onDisputeSubmitted,
  });

  @override
  State<DelegateDisputeBottomSheet> createState() =>
      _DelegateDisputeBottomSheetState();
}

class _DelegateDisputeBottomSheetState
    extends State<DelegateDisputeBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Signaler un problème'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quel est le problème ?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Reason buttons
              _ReasonButton(
                label: 'Chauffeur n\'a pas attendu',
                icon: Icons.schedule,
                onTap: () {
                  setState(() =>
                      _selectedReason =
                          'Chauffeur n\'a pas attendu');
                },
                isSelected: _selectedReason ==
                    'Chauffeur n\'a pas attendu',
              ),
              const SizedBox(height: 10),
              _ReasonButton(
                label: 'Trajet incorrect / détour',
                icon: Icons.directions,
                onTap: () {
                  setState(() =>
                      _selectedReason = 'Trajet incorrect');
                },
                isSelected:
                    _selectedReason == 'Trajet incorrect',
              ),
              const SizedBox(height: 10),
              _ReasonButton(
                label: 'Problème de sécurité',
                icon: Icons.security,
                onTap: () {
                  setState(() =>
                      _selectedReason =
                          'Problème de sécurité');
                },
                isSelected:
                    _selectedReason == 'Problème de sécurité',
              ),
              const SizedBox(height: 20),

              // Comment field
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Détail du problème...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final reason = (_selectedReason ?? _reasonController.text).trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selectionnez ou renseignez un motif.'),
                        ),
                      );
                      return;
                    }
                    await widget.onDisputeSubmitted(reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('SOUMETTRE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _ReasonButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dangerWithOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.danger : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.danger
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(
                  color: isSelected
                      ? AppColors.danger
                      : AppColors.text,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.danger,
              ),
          ],
        ),
      ),
    );
  }
}

