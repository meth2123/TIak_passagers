import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/driver.dart';

/// ÉCRAN L — NOTATION
/// 5 étoiles grand format
/// Tags : "Ponctuel" "Courtois" "Conduite sûre" "Propre"
/// Commentaire (optionnel)
/// Pourboire : [250] [500] [1 000] [Autre] FCFA
/// → Transfert Wave/OM séparé direct chauffeur
class RatingPage extends ConsumerStatefulWidget {
  final Driver driver;

  const RatingPage({
    super.key,
    required this.driver,
  });

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  int _rating = 0;
  List<String> _selectedTags = [];
  final TextEditingController _commentController =
      TextEditingController();
  int? _selectedTip;

  final List<String> _availableTags = [
    'Ponctuel',
    'Courtois',
    'Conduite sûre',
    'Propre',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noter le chauffeur'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver info
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        AppColors.primaryWithOpacity(0.1),
                    backgroundImage:
                        widget.driver.photoUrl != null
                            ? NetworkImage(
                                widget.driver.photoUrl!)
                            : null,
                    child: widget.driver.photoUrl == null
                        ? Icon(Icons.person,
                            size: 32,
                            color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        Text(
                          widget.driver.motoModel ?? 'Moto',
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
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Star Rating
              Text(
                'Votre note',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _rating = index + 1);
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8),
                        child: Icon(
                          Icons.star,
                          size: 60,
                          color: index < _rating
                              ? AppColors.warning
                              : AppColors.border,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  _rating > 0
                      ? '$_rating ${_rating == 1 ? 'étoile' : 'étoiles'}'
                      : 'Sélectionnez une note',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: _rating > 0
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // Tags
              Text(
                'Qualités (optionnel)',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor:
                        AppColors.primaryWithOpacity(0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Comment
              Text(
                'Commentaire (optionnel)',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Partagez votre retour...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tip Section
              Text(
                'Donner un pourboire',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              Text(
                'Votre pourboire ira directement au chauffeur',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [250, 500, 1000].map((tip) {
                  final isSelected = _selectedTip == tip;
                  return GestureDetector(
                    onTap: () {
                      setState(() =>
                          _selectedTip = isSelected ? null : tip);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryWithOpacity(0.1)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        '+$tip FCFA',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.text,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  _showCustomTipDialog();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit,
                          color: AppColors.primary,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Montant personnalisé',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _submitRating();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SOUMETTRE',
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTipDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Montant du pourboire'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'FCFA',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() =>
                    _selectedTip =
                        int.parse(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _submitRating() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez donner une note'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // TODO: Call POST /api/trips/:id/rate
    // {
    //   score: _rating,
    //   comment: _commentController.text,
    //   tags: _selectedTags,
    //   tip_amount_fcfa: _selectedTip ?? 0
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Merci pour votre évaluation ! ✓'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/map',
          (route) => false,
        );
      }
    });
  }
}

