import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/theme/app_theme.dart';

final _loadingProvider = StateProvider<bool>((ref) => false);
final _socialLoadingProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    ref.read(_loadingProvider.notifier).state = true;
    try {
      await ApiClient().init();
      await ref.read(authRepositoryProvider).login(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() => _error = 'بيانات الدخول غير صحيحة');
    } finally {
      ref.read(_loadingProvider.notifier).state = false;
    }
  }

  Future<void> _socialLogin(String provider) async {
    ref.read(_socialLoadingProvider.notifier).state = provider;
    setState(() => _error = null);
    try {
      final data = provider == 'google'
          ? await SocialAuthService.signInWithGoogle()
          : await SocialAuthService.signInWithApple();

      await ref.read(authRepositoryProvider).socialLogin(
            provider: data['provider']!,
            token: data['token']!,
            name: data['name'],
            email: data['email'],
            userId: data['user_id'],
          );
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (e.toString().contains('cancelled')) return;
      if (mounted) {
        setState(() => _error = provider == 'google' ? 'فشل تسجيل الدخول بـ Google' : 'فشل تسجيل الدخول بـ Apple');
      }
    } finally {
      ref.read(_socialLoadingProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final loading = ref.watch(_loadingProvider);
    final socialLoading = ref.watch(_socialLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.cloud_outlined, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Quadro Cloud',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                const Text('Client Portal',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 48),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.login, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: l.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: loading ? null : _login,
                            child: loading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(l.loginButton),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('او', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 20),

                      _SocialButton(
                        onTap: socialLoading != null ? null : () => _socialLogin('google'),
                        loading: socialLoading == 'google',
                        icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                        label: 'متابعة مع Google',
                        borderColor: Colors.grey.shade300,
                        textColor: const Color(0xFF1A1A2E),
                      ),

                      if (Platform.isIOS) ...[
                        const SizedBox(height: 12),
                        _SocialButton(
                          onTap: socialLoading != null ? null : () => _socialLogin('apple'),
                          loading: socialLoading == 'apple',
                          icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                          label: 'متابعة مع Apple',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final Widget icon;
  final String label;
  final Color? backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialButton({
    required this.onTap,
    required this.loading,
    required this.icon,
    required this.label,
    this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                icon,
                const SizedBox(width: 10),
                Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
      ),
    );
  }
}
