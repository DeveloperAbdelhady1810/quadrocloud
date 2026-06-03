import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/payment_repository.dart';
import '../data/payment_model.dart';
import '../../../core/theme/app_theme.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentHistory)),
      body: paymentsAsync.when(
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
                onPressed: () => ref.invalidate(paymentsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
        data: (payments) => payments.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l.noPayments, style: const TextStyle(color: Colors.grey)),
              ]))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(paymentsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
                ),
              ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == 'success';
    final isCash = payment.method == 'cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isSuccess ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCash ? Icons.money : Icons.credit_card,
            color: isSuccess ? AppTheme.success : AppTheme.danger,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.invoiceNumber ?? 'دفعة', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(isCash ? 'نقدي' : 'Paymob', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${payment.amount.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16,
                color: isSuccess ? AppTheme.success : AppTheme.danger,
              )),
          Text(payment.paidAt?.substring(0, 10) ?? '',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ]),
    );
  }
}
