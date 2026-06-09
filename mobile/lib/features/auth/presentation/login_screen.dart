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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));
    _cardFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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

  void _showOtpSheet(BuildContext context) {
    final router = GoRouter.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtpLoginSheet(
        onLogin: (email, otp) async {
          await ref.read(authRepositoryProvider).otpLogin(email, otp);
          router.go('/home');
        },
      ),
    );
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
        setState(() => _error = provider == 'google'
            ? 'فشل تسجيل الدخول بـ Google'
            : 'فشل تسجيل الدخول بـ Apple');
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(children: [

                // ── Brand header ────────────────────────────────────────────
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Column(children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.cloud_outlined, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Quadro Cloud',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'Client Portal',
                          style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Login card ───────────────────────────────────────────────
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // Title
                        Text(
                          l.login,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أدخل بياناتك للمتابعة',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 24),

                        // Error banner
                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        // Form
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
                            const SizedBox(height: 14),
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
                              onFieldSubmitted: (_) => loading ? null : _login(),
                            ),
                            const SizedBox(height: 24),
                            _LoginButton(loading: loading, onTap: loading ? null : _login, label: l.loginButton),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('أو', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ),
                          const Expanded(child: Divider()),
                        ]),

                        const SizedBox(height: 20),

                        // Social buttons
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
                        _SocialButton(
                          onTap: socialLoading != null ? null : () => _socialLogin('google'),
                          loading: socialLoading == 'google',
                          icon: _GoogleIcon(),
                          label: 'متابعة مع Google',
                          borderColor: Colors.grey.shade200,
                          textColor: AppTheme.textPrimary,
                        ),


                        // OTP login link
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _showOtpSheet(context),
                          child: Center(
                            child: Text(
                              'لديك كود دخول؟ اضغط هنا',
                              style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
      ]),
    );
  }
}

class _LoginButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  final String label;
  const _LoginButton({required this.loading, required this.onTap, required this.label});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.loading
                  ? [Colors.grey.shade400, Colors.grey.shade400]
                  : [AppTheme.primary, const Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.loading
                ? []
                : [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _OtpLoginSheet extends StatefulWidget {
  final Future<void> Function(String email, String otp) onLogin;
  const _OtpLoginSheet({required this.onLogin});

  @override
  State<_OtpLoginSheet> createState() => _OtpLoginSheetState();
}

class _OtpLoginSheetState extends State<_OtpLoginSheet> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (email.isEmpty || otp.length != 6) {
      setState(() => _error = 'أدخل البريد الإلكتروني والكود المكون من 6 أرقام');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onLogin(email, otp);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'الكود غير صحيح أو منتهي الصلاحية'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 20),
        const Text('الدخول بكود', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('أدخل بريدك والكود الذي أرسله لك المدير', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'كود الدخول (6 أرقام)',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
          onSubmitted: (_) => _loading ? null : _submit(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('دخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _SocialButton extends StatefulWidget {
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
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.onTap != null) setState(() => _pressed = true); },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor ?? Colors.transparent),
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    widget.icon,
                    const SizedBox(width: 10),
                    Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                  ]),
          ),
        ),
      ),
    );
  }
}
