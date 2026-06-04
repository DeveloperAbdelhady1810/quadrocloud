import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/invoice_repository.dart';
import '../data/invoice_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.invoices)),
      body: invoicesAsync.when(
        loading: () => const ShimmerList(count: 5),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(invoicesProvider),
          retryLabel: l.retry,
        ),
        data: (invoices) => invoices.isEmpty
            ? EmptyState(icon: Icons.receipt_outlined, message: l.noInvoices)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(invoicesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: _InvoiceCard(invoice: invoices[i], ref: ref),
                  ),
                ),
              ),
      ),
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  final InvoiceModel invoice;
  final WidgetRef ref;
  const _InvoiceCard({required this.invoice, required this.ref});

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _paying = false;

  Color _statusColor() {
    switch (widget.invoice.status) {
      case 'paid': return AppTheme.success;
      case 'overdue': return AppTheme.danger;
      default: return AppTheme.warning;
    }
  }

  String _statusLabel(AppLocalizations l) {
    switch (widget.invoice.status) {
      case 'paid': return l.paid;
      case 'overdue': return l.overdue;
      case 'cancelled': return l.cancelled;
      default: return l.unpaid;
    }
  }

  IconData _statusIcon() {
    switch (widget.invoice.status) {
      case 'paid': return Icons.check_circle_outline_rounded;
      case 'overdue': return Icons.error_outline_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  Future<void> _pay(BuildContext context, AppLocalizations l) async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final url = await widget.ref.read(invoiceRepositoryProvider).initiatePayment(widget.invoice.id);
      if (context.mounted) {
        context.go('/invoices/pay/${widget.invoice.id}/${Uri.encodeComponent(url)}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.error)));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top row: invoice # + status chip
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.receipt_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(widget.invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_statusIcon(), size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(_statusLabel(l), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
          ]),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Amount + date row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.amount, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 3),
              Text(
                '${widget.invoice.amount.toStringAsFixed(0)} ج.م',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                widget.invoice.isPaid ? l.paidAt : l.dueDate,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                widget.invoice.isPaid
                    ? (widget.invoice.paidAt ?? '')
                    : (widget.invoice.dueDate ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]),
          ]),

          // Pay button
          if (widget.invoice.isUnpaid || widget.invoice.isOverdue) ...[
            const SizedBox(height: 14),
            PressableCard(
              onTap: _paying ? () {} : () => _pay(context, l),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _paying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(l.onlinePay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                ),
              ),
            ),
          ],

          // Paid indicator
          if (widget.invoice.isPaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.invoice.paymentMethod == 'cash' ? 'دفع نقدي' : 'دفع أونلاين - Paymob',
                  style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
