import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:tiak_passenger/core/constants/app_colors.dart';
import 'package:tiak_passenger/core/constants/app_constants.dart';
import 'package:tiak_passenger/core/services/auth_service.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final FormGroup _phoneForm = FormGroup({
    'phone': FormControl<String>(
      validators: [
        Validators.required,
        Validators.pattern(AppConstants.phoneDigitsOnlyPattern),
      ],
    ),
  });

  final FormGroup _otpForm = FormGroup({
    'otp': FormControl<String>(
      validators: [Validators.required, Validators.pattern(r'^\d{6}$')],
    ),
  });

  bool _isPhoneStep = true;
  bool _isLoading = false;
  int _resendTimer = 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
        return true;
      }
      return false;
    });
  }

  Future<void> _sendOtp() async {
    if (!_phoneForm.valid) return;

    setState(() => _isLoading = true);

    try {
      final phoneValue = _phoneForm.control('phone').value as String;
      final fullPhone = '${AppConstants.phonePrefix} $phoneValue';

      final success = await ref.read(authServiceProvider).sendOtp(fullPhone);

      if (success && mounted) {
        setState(() {
          _isPhoneStep = false;
          _isLoading = false;
        });
        _startResendTimer();
      }
    } catch (e) {
      // Handle error
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi du code')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpForm.valid) return;

    setState(() => _isLoading = true);

    try {
      final phoneValue = _phoneForm.control('phone').value as String;
      final fullPhone = '${AppConstants.phonePrefix} $phoneValue';
      final otp = _otpForm.control('otp').value as String;

      final success = await ref
          .read(authServiceProvider)
          .verifyOtp(fullPhone, otp);

      if (!mounted) {
        return;
      }

      if (success) {
        context.go('/profile-creation');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code incorrect')));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur de vérification')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBackToPhone() {
    setState(() => _isPhoneStep = true);
    _otpForm.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isPhoneStep
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _goBackToPhone,
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 156,
                      child: Image.asset(
                        AppConstants.nuDemLogoAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        AppConstants.deliveryFrameAsset,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConstants.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Header
              Text(
                _isPhoneStep
                    ? AppStrings.enterPhoneNumber
                    : 'Vérifiez votre numéro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isPhoneStep
                    ? 'Nous vous enverrons un code de vérification'
                    : 'Entrez le code à 6 chiffres envoyé au ${_phoneForm.control('phone').value != null ? "${AppConstants.phonePrefix} ${_phoneForm.control('phone').value}" : "votre numéro"}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 40),

              // Form
              if (_isPhoneStep) _buildPhoneForm() else _buildOtpForm(),

              const Spacer(),

              // Info text
              if (_isPhoneStep)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Utilisez le format: XX XXX XX XX\nExemple: 77 123 45 67',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return ReactiveForm(
      formGroup: _phoneForm,
      child: Column(
        children: [
          ReactiveTextField<String>(
            formControlName: 'phone',
            decoration: InputDecoration(
              labelText: AppStrings.phoneNumberHint,
              prefixText: '${AppConstants.phonePrefix} ',
              hintText: '77 123 45 67',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendOtp(),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(AppStrings.sendOtp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return ReactiveForm(
      formGroup: _otpForm,
      child: Column(
        children: [
          ReactiveTextField<String>(
            formControlName: 'otp',
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
              hintText: '123456',
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            onSubmitted: (_) => _verifyOtp(),
          ),

          const SizedBox(height: 16),

          // Resend timer/button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Renvoyer le code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _resendTimer == 0 ? _sendOtp : null,
                child: Text(
                  _resendTimer > 0 ? '(${_resendTimer}s)' : 'Renvoyer',
                  style: TextStyle(
                    color: _resendTimer > 0
                        ? AppColors.textHint
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Vérifier'),
            ),
          ),
        ],
      ),
    );
  }
}
