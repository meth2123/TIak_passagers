import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/user.dart';
import 'package:tiak_passenger/core/services/auth_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final authService = ref.read(authServiceProvider);
    setState(() {
      _user = authService.getUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Parametres',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadUser(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeaderCard(
              user: user,
              onEditPressed: _showEditProfileSheet,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Preferences',
              children: [
                _ActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Paiement prefere',
                  subtitle: _paymentLabel(user?.preferredPayment),
                  onTap: _showPaymentPicker,
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.language_outlined,
                  title: 'Langue',
                  subtitle: _languageLabel(user?.lang),
                  onTap: _showLanguagePicker,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Mon compte',
              children: [
                _ActionTile(
                  icon: Icons.history,
                  title: 'Historique des courses',
                  subtitle: 'Voir mes trajets passes',
                  onTap: () => context.push('/trips-history'),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.help_outline,
                  title: 'Aide et securite',
                  subtitle: 'Wave/Orange Money uniquement',
                  onTap: _showHelpDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se deconnecter'),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      default:
        return 'Wave';
    }
  }

  String _languageLabel(Language? language) {
    switch (language) {
      case Language.wo:
        return 'Wolof';
      case Language.fr:
      default:
        return 'Francais';
    }
  }

  Future<void> _showEditProfileSheet() async {
    final user = _user;
    final nameController = TextEditingController(text: user?.name ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier le profil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  hintText: 'Ex: Aminata Ndiaye',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) {
                    return;
                  }
                  final authService = ref.read(authServiceProvider);
                  await authService.updateUserProfile(name: newName);
                  _loadUser();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
  }

  Future<void> _showPaymentPicker() async {
    final selected = await showModalBottomSheet<PaymentMethod>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.waves_rounded),
                title: const Text('Wave'),
                onTap: () => Navigator.pop(context, PaymentMethod.wave),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Orange Money'),
                onTap: () => Navigator.pop(context, PaymentMethod.orangeMoney),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await ref
          .read(authServiceProvider)
          .updateUserProfile(preferredPayment: selected);
      _loadUser();
    }
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showDialog<Language>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choisir la langue'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, Language.fr),
            child: const Text('Francais'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, Language.wo),
            child: const Text('Wolof'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await ref.read(authServiceProvider).updateUserProfile(language: selected);
      _loadUser();
    }
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et securite'),
        content: const Text(
          'Tiak-Tiak accepte uniquement Wave et Orange Money. '
          'Cela protege le passager et le chauffeur grace au paiement securise.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authServiceProvider).logout();
      if (mounted) {
        context.go('/auth');
      }
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user, required this.onEditPressed});

  final User? user;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryWithOpacity(0.14),
            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Utilisateur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '+221 -- --- -- --',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
