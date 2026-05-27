import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  PhoneNumber? _phone;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    final phoneOk = _phone != null && _phone!.number.length >= 7;
    final nameOk = Validators.name(_nameCtrl.text) == null;
    return phoneOk && nameOk;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _phone == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final profile = UserProfile(
      mobile: _phone!.number,
      countryCode: '+${_phone!.countryCode.replaceAll('+', '')}',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(profileProvider.notifier).save(profile);
    await ref.read(authProvider.notifier).setLoggedIn(true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mosque,
                        size: 48, color: AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(height: 24),
                Text(K.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(K.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 40),
                IntlPhoneField(
                  controller: _phoneCtrl,
                  initialCountryCode: 'IN',
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  onChanged: (p) => setState(() => _phone = p),
                  invalidNumberMessage: 'Invalid mobile number',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.emailOptional,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isValid && !_saving ? _submit : null,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Continue'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your data is stored only on this device. No OTP, no SMS, nothing leaves your phone.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
