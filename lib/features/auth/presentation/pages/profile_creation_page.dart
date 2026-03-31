import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/user.dart';
import 'package:tiak_passenger/core/services/auth_service.dart';

class ProfileCreationPage extends ConsumerStatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  ConsumerState<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends ConsumerState<ProfileCreationPage> {
  final _nameController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.wave;
  Language _language = Language.fr;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateUserProfile(
            name: name,
            preferredPayment: _paymentMethod,
            language: _language,
          );
      if (!mounted) return;
      context.go('/map');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer votre profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Ex: Aminata Ndiaye',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Language>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Langue'),
              items: const [
                DropdownMenuItem(value: Language.fr, child: Text('Français')),
                DropdownMenuItem(value: Language.wo, child: Text('Wolof')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _language = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Paiement préféré'),
              items: const [
                DropdownMenuItem(value: PaymentMethod.wave, child: Text('Wave')),
                DropdownMenuItem(
                  value: PaymentMethod.orangeMoney,
                  child: Text('Orange Money'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

