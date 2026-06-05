import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(ticketRepositoryProvider).createTicket(
            _titleCtrl.text.trim(),
            _msgCtrl.text.trim(),
          );
      ref.invalidate(ticketsProvider);
      if (mounted) context.go('/tickets');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال التذكرة')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(title: Text(l.newTicket)),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Intro banner ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'سيرد عليك فريق الدعم في أقرب وقت ممكن',
                        style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Title field ────────────────────────────────────────────────
                _Label(text: l.ticketTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'مثال: مشكلة في الاتصال بالسيرفر',
                    prefixIcon: const Icon(Icons.title_rounded),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _titleCtrl,
                      builder: (_, v, __) => v.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: _titleCtrl.clear,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 20),

                // ── Message field ──────────────────────────────────────────────
                _Label(text: l.message),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _msgCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'اشرح المشكلة بالتفصيل حتى نتمكن من مساعدتك بشكل أسرع...',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                  validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 32),

                // ── Submit ─────────────────────────────────────────────────────
                PressableCard(
                  onTap: _loading ? () {} : _submit,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(l.send, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary));
  }
}
