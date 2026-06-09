import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../data/client_model.dart';
import '../../community/data/community_repository.dart';
import '../../../core/utils/storage.dart';
import '../../../core/theme/app_theme.dart';

final _localeProvider = StateProvider<String>((ref) => 'ar');

final _cachedClientProvider = FutureProvider<ClientModel?>((ref) async {
  return ref.read(authRepositoryProvider).getCachedClient();
});

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
    final clientAsync = ref.watch(_cachedClientProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [

          // ── Profile section ──────────────────────────────────────────────
          _ProfileCard(client: clientAsync.valueOrNull),
          const SizedBox(height: 24),

          // ── Edit profile ─────────────────────────────────────────────────
          _SectionHeader(title: 'تعديل الملف الشخصي'),
          _SettingCard(child: _EditProfileForm(
            client: clientAsync.valueOrNull,
            onSaved: () => ref.invalidate(_cachedClientProvider),
          )),
          const SizedBox(height: 16),

          // ── Language ─────────────────────────────────────────────────────
          _SectionHeader(title: l.changeLanguage),
          _SettingCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اختر اللغة المفضلة', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'ar',
                      label: Text('العربية'),
                      icon: Icon(Icons.language, size: 16),
                    ),
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text('English'),
                      icon: Icon(Icons.language, size: 16),
                    ),
                  ],
                  selected: {locale},
                  onSelectionChanged: (values) => _changeLocale(values.first),
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Privacy / visibility ──────────────────────────────────────────
          _SectionHeader(title: 'الخصوصية في مجتمع العملاء'),
          _SettingCard(child: _VisibilityRequestForm()),
          const SizedBox(height: 16),

          // ── Change password ───────────────────────────────────────────────
          _SectionHeader(title: l.changePassword),
          _SettingCard(child: _ChangePasswordForm()),
          const SizedBox(height: 32),

          // ── Logout ────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                    const SizedBox(width: 10),
                    Text(l.logout, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ClientModel? client;
  const _ProfileCard({this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            client?.name ?? 'Client Portal',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            client?.email ?? 'Quadro Cloud',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (client?.companyName != null) ...[
            const SizedBox(height: 2),
            Text(client!.companyName!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Text('نشط', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final ClientModel? client;
  final VoidCallback onSaved;
  const _EditProfileForm({this.client, required this.onSaved});

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.client?.phone ?? '');
    _companyCtrl = TextEditingController(text: widget.client?.companyName ?? '');
    _addressCtrl = TextEditingController(text: widget.client?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            companyName: _companyCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
        setState(() => _expanded = false);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في حفظ البيانات')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              const Text('تعديل البيانات الشخصية',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
              const Spacer(),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.textSecondary),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الشركة', prefixIcon: Icon(Icons.business_outlined)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('حفظ التغييرات'),
                  ),
                ),
              ]),
            ),
          ),
      ]),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور الحالية غير صحيحة')));
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
              prefixIcon: const Icon(Icons.lock_outline_rounded),
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
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

// ─── Visibility Request Form ──────────────────────────────────────────────────

class _VisibilityRequestForm extends ConsumerStatefulWidget {
  const _VisibilityRequestForm();
  @override
  ConsumerState<_VisibilityRequestForm> createState() => _VisibilityRequestFormState();
}

class _VisibilityRequestFormState extends ConsumerState<_VisibilityRequestForm> {
  String? _selected;
  bool _loading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(communityRepositoryProvider).requestVisibility(_selected!);
      setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Row(children: [
          Icon(Icons.check_circle_outline, color: AppTheme.success),
          SizedBox(width: 10),
          Expanded(child: Text('تم إرسال طلبك للمراجعة. سيتم تطبيق الإخفاء بعد مراجعة الإدارة.',
              style: TextStyle(color: AppTheme.success, fontSize: 13))),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('يظهر اسمك وشركتك لعملاء Quadro Cloud الآخرين. يمكنك طلب إخفاء بعض بياناتك.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        _VisibilityOption(
          label: 'إخفاء اسمي فقط',
          value: 'hide_name',
          selected: _selected,
          onTap: (v) => setState(() => _selected = v == _selected ? null : v),
        ),
        _VisibilityOption(
          label: 'إخفاء اسم الشركة فقط',
          value: 'hide_company',
          selected: _selected,
          onTap: (v) => setState(() => _selected = v == _selected ? null : v),
        ),
        _VisibilityOption(
          label: 'إخفاء كل بياناتي',
          value: 'hide_all',
          selected: _selected,
          onTap: (v) => setState(() => _selected = v == _selected ? null : v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selected == null || _loading) ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('إرسال الطلب'),
          ),
        ),
      ]),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final void Function(String) onTap;
  const _VisibilityOption({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
            fontSize: 14,
          )),
        ]),
      ),
    );
  }
}
