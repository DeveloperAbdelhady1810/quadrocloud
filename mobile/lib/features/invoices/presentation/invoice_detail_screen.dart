import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/invoice_repository.dart';
import '../data/invoice_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('فاتورة #$invoiceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
          retryLabel: l.retry,
        ),
        data: (invoice) => _InvoiceDetailBody(invoice: invoice),
      ),
    );
  }
}

class _InvoiceDetailBody extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailBody({required this.invoice});

  @override
  ConsumerState<_InvoiceDetailBody> createState() => _InvoiceDetailBodyState();
}

class _InvoiceDetailBodyState extends ConsumerState<_InvoiceDetailBody> {
  bool _paying = false;
  bool _sending = false;

  Color get _statusColor {
    switch (widget.invoice.status) {
      case 'paid': return AppTheme.success;
      case 'overdue': return AppTheme.danger;
      default: return AppTheme.warning;
    }
  }

  String get _statusLabel {
    switch (widget.invoice.status) {
      case 'paid': return 'مدفوعة';
      case 'overdue': return 'متأخرة';
      case 'cancelled': return 'ملغية';
      default: return 'غير مدفوعة';
    }
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final url = await ref.read(invoiceRepositoryProvider).initiatePayment(widget.invoice.id);
      if (mounted) {
        context.go('/invoices/pay/${widget.invoice.id}/${Uri.encodeComponent(url)}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الاتصال بنظام الدفع')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _sendEmail() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(invoiceRepositoryProvider).sendEmail(widget.invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الفاتورة إلى بريدك الإلكتروني')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال البريد الإلكتروني')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final statusColor = _statusColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Status header card ─────────────────────────────────────────────────
        AnimatedListItem(
          index: 0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withValues(alpha: 0.15), statusColor.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  inv.isPaid ? Icons.check_circle_rounded : inv.isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                  color: statusColor, size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(inv.amount.toStringAsFixed(0),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: statusColor)),
                Text('ج.م', style: TextStyle(fontSize: 13, color: statusColor.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ),

        // ── Details card ───────────────────────────────────────────────────────
        AnimatedListItem(
          index: 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              _DetailRow(icon: Icons.receipt_outlined, label: 'رقم الفاتورة', value: inv.invoiceNumber),
              if (inv.description != null)
                _DetailRow(icon: Icons.work_outline_rounded, label: 'الخدمة', value: inv.description!),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: inv.isPaid ? 'تاريخ الدفع' : 'تاريخ الاستحقاق',
                value: inv.isPaid ? (inv.paidAt ?? '-') : (inv.dueDate ?? '-'),
                valueColor: inv.isOverdue ? AppTheme.danger : null,
              ),
              if (inv.isPaid && inv.paymentMethod != null)
                _DetailRow(
                  icon: inv.paymentMethod == 'cash' ? Icons.money_rounded : Icons.credit_card_rounded,
                  label: 'طريقة الدفع',
                  value: inv.paymentMethod == 'cash' ? 'نقدي' : 'Paymob (أونلاين)',
                  isLast: true,
                ),
            ]),
          ),
        ),

        // ── Actions ────────────────────────────────────────────────────────────
        AnimatedListItem(
          index: 2,
          child: Column(children: [

            // Pay button
            if (inv.isUnpaid || inv.isOverdue) ...[
              PressableCard(
                onTap: _paying ? () {} : _pay,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _paying
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('ادفع الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Send email button
            PressableCard(
              onTap: _sending ? () {} : _sendEmail,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: _sending
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.email_outlined, color: AppTheme.primary, size: 20),
                          SizedBox(width: 10),
                          Text('إرسال الفاتورة بالبريد الإلكتروني',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                        ]),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: valueColor ?? AppTheme.textPrimary,
              )),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 46, color: Color(0xFFF1F5F9)),
    ]);
  }
}
