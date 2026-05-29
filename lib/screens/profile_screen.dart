import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../utils/validators.dart';
import '../widgets/initials_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  PhoneNumber? _phoneNumber;
  String? _avatarPath;
  bool _dirty = false;
  bool _initialized = false;
  bool _saving = false;

  void _initFrom(UserProfile p) {
    _name.text = p.name;
    _email.text = p.email ?? '';
    _city.text = p.city ?? '';
    _phone.text = p.mobile;
    _avatarPath = p.avatarPath;
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dst = p.join(dir.path,
        'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}');
    await File(picked.path).copy(dst);
    setState(() {
      _avatarPath = dst;
      _dirty = true;
    });
  }

  void _avatarSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _avatarPath = null;
                    _dirty = true;
                  });
                  Navigator.of(sheetCtx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(UserProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final newMobile = _phoneNumber?.number ?? current.mobile;
    final newCode = _phoneNumber != null
        ? '+${_phoneNumber!.countryCode.replaceAll('+', '')}'
        : current.countryCode;
    final mobileChanged =
        newMobile != current.mobile || newCode != current.countryCode;

    final updated = current.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      clearEmail: _email.text.trim().isEmpty,
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      clearCity: _city.text.trim().isEmpty,
      avatarPath: _avatarPath,
      clearAvatar: _avatarPath == null,
      mobile: newMobile,
      countryCode: newCode,
    );

    final ok = await ref.read(profileControllerProvider).save(updated);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
      return;
    }

    // Save returned false because another account already exists at this
    // new mobile number. Ask the user if they want to switch to that account.
    if (!mobileChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save failed')),
      );
      return;
    }

    final switchOk = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch account?'),
        content: Text(
          'An account already exists under $newCode $newMobile. '
          'Do you want to switch to that account? Your current data stays linked to your previous number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (switchOk == true) {
      await ref.read(profileControllerProvider).switchOrCreate(
            countryCode: newCode,
            mobile: newMobile,
            name: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched account')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profile == null
          ? const Center(child: Text('No profile yet'))
          : _form(theme, profile),
    );
  }

  Widget _form(ThemeData theme, UserProfile profile) {
    if (!_initialized) _initFrom(profile);
    return Form(
      key: _formKey,
      onChanged: () => setState(() => _dirty = true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Center(
            child: Stack(
              children: [
                InitialsAvatar(
                  name: _name.text.isEmpty ? profile.name : _name.text,
                  avatarPath: _avatarPath,
                  radius: 56,
                  onTap: _avatarSheet,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      iconSize: 18,
                      color: Colors.white,
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: _avatarSheet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _name.text.isEmpty ? profile.name : _name.text,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Center(
            child: Text(
              profile.email ?? profile.fullPhone,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: Validators.name,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.emailOptional,
          ),
          const SizedBox(height: 12),
          IntlPhoneField(
            controller: _phone,
            initialCountryCode: 'IN',
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText:
                  'Changing the number switches you to a different account.',
            ),
            onChanged: (n) {
              _phoneNumber = n;
              setState(() => _dirty = true);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'City (optional)',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _dirty && !_saving ? () => _save(profile) : null,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
