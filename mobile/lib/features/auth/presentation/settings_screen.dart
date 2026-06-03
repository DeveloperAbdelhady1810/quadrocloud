import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/storage.dart';
import '../../../core/theme/app_theme.dart';

final _localeProvider = StateProvider<String>((ref) => 'ar');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await AppStorage.getLocale();
    ref.read(_localeProvider.notifier).state = locale;
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authRepositoryProvider).logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _changeLocale(String locale) async {
    await ref.read(authRepositoryProvider).updateLocale(locale);
    await AppStorage.setLocale(locale);
    ref.read(_localeProvider.notifier).state = locale;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أعد تشغيل التطبيق لتفعيل اللغة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(_localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l.changeLanguage),
          _SettingCard(
            child: Column(children: [
              RadioListTile<String>(
                value: 'ar',
                groupValue: locale,
                onChanged: (v) { if (v != null) _changeLocale(v); },
                title: const Text('العربية'),
                activeColor: AppTheme.primary,
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: locale,
                onChanged: (v) { if (v != null) _changeLocale(v); },
                title: const Text('English'),
                activeColor: AppTheme.primary,
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: l.changePassword),
          _SettingCard(child: _ChangePasswordForm()),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: Text(l.logout),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: child,
    );
  }
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(_currentCtrl.text, _newCtrl.text);
      _currentCtrl.clear();
      _newCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور الحالية غير صحيحة')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(children: [
          TextFormField(
            controller: _currentCtrl,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: l.currentPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: l.newPassword,
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) => v != null && v.length < 8 ? 'لا يقل عن 8 أحرف' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l.save),
            ),
          ),
        ]),
      ),
    );
  }
}
