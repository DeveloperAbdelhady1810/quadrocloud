import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/invoice_repository.dart';
import '../data/invoice_model.dart';
import '../../../core/theme/app_theme.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.invoices)),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l.error, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(invoicesProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
        data: (invoices) => invoices.isEmpty
            ? Center(child: Text(l.noInvoices, style: const TextStyle(color: Colors.grey)))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(invoicesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) => _InvoiceCard(invoice: invoices[i], ref: ref),
                ),
              ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final WidgetRef ref;
  const _InvoiceCard({required this.invoice, required this.ref});

  Color _statusColor() {
    switch (invoice.status) {
      case 'paid': return AppTheme.success;
      case 'overdue': return AppTheme.danger;
      default: return AppTheme.warning;
    }
  }

  String _statusLabel(AppLocalizations l) {
    switch (invoice.status) {
      case 'paid': return l.paid;
      case 'overdue': return l.overdue;
      case 'cancelled': return l.cancelled;
      default: return l.unpaid;
    }
  }

  Future<void> _pay(BuildContext context, AppLocalizations l) async {
    try {
      final url = await ref.read(invoiceRepositoryProvider).initiatePayment(invoice.id);
      if (context.mounted) {
        context.go('/invoices/pay/${invoice.id}/${Uri.encodeComponent(url)}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.error)));
      }
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
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(l), style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.amount, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text('${invoice.amount.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(invoice.isPaid ? l.paidAt : l.dueDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text(invoice.isPaid ? (invoice.paidAt ?? '') : (invoice.dueDate ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ]),
          if (invoice.isUnpaid || invoice.isOverdue) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pay(context, l),
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text(l.onlinePay),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                ),
              ),
            ]),
          ],
          if (invoice.isPaid) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
              const SizedBox(width: 6),
              Text(invoice.paymentMethod == 'cash' ? 'دفع نقدي' : 'دفع أونلاين - Paymob',
                  style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ],
        ]),
      ),
    );
  }
}
