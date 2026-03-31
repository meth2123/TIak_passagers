import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/models/user.dart';
import 'package:tiak_passenger/core/services/auth_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  User? _user;
  bool _notificationsEnabled = true;
  bool _promoNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final authService = ref.read(authServiceProvider);
    setState(() {
      _user = authService.getUserData();
      _notificationsEnabled = authService.notificationsEnabled;
      _promoNotificationsEnabled = authService.promoNotificationsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Compte',
            children: [
              _StaticValueTile(
                icon: Icons.phone_outlined,
                title: 'Numero',
                value: user?.phone ?? '+221 -- --- -- --',
              ),
              const Divider(height: 1),
              _StaticValueTile(
                icon: Icons.verified_user_outlined,
                title: 'Statut',
                value: user?.status == UserStatus.active ? 'Actif' : 'Suspendu',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Preferences',
            children: [
              _ActionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Paiement prefere',
                subtitle: _paymentLabel(user?.preferredPayment),
                onTap: _pickPayment,
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.language_outlined,
                title: 'Langue',
                subtitle: _languageLabel(user?.lang),
                onTap: _pickLanguage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile.adaptive(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                title: const Text('Notifications de course'),
                subtitle: const Text('Statuts course, chauffeur, paiement'),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: _promoNotificationsEnabled,
                onChanged: _togglePromoNotifications,
                title: const Text('Offres et promotions'),
                subtitle: const Text('Codes promo et campagnes locales'),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paiements 100% securises via Wave et Orange Money. Aucun cash n\'est accepte sur Tiak-Tiak.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPayment() async {
    final selected = await showModalBottomSheet<PaymentMethod>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Wave'),
                leading: const Icon(Icons.waves_rounded),
                onTap: () => Navigator.pop(context, PaymentMethod.wave),
              ),
              ListTile(
                title: const Text('Orange Money'),
                leading: const Icon(Icons.account_balance_wallet_outlined),
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
      _loadSettings();
    }
  }

  Future<void> _pickLanguage() async {
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
      _loadSettings();
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await ref.read(authServiceProvider).setNotificationsEnabled(enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _togglePromoNotifications(bool enabled) async {
    await ref.read(authServiceProvider).setPromoNotificationsEnabled(enabled);
    setState(() {
      _promoNotificationsEnabled = enabled;
    });
  }

  String _paymentLabel(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.wave:
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
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

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

class _StaticValueTile extends StatelessWidget {
  const _StaticValueTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
