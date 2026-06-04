import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/payment_repository.dart';
import '../data/payment_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentHistory)),
      body: paymentsAsync.when(
        loading: () => const ShimmerList(count: 6),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(paymentsProvider),
          retryLabel: l.retry,
        ),
        data: (payments) => payments.isEmpty
            ? EmptyState(icon: Icons.payment_outlined, message: l.noPayments)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(paymentsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: _PaymentCard(payment: payments[i], isLast: i == payments.length - 1),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isLast;
  const _PaymentCard({required this.payment, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == 'success';
    final isCash = payment.method == 'cash';
    final color = isSuccess ? AppTheme.success : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCash ? Icons.money_rounded : Icons.credit_card_rounded,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            payment.invoiceNumber ?? 'دفعة',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              isCash ? 'نقدي' : 'Paymob',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ]),
        ])),

        // Amount + date
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${payment.amount.toStringAsFixed(0)} ج.م',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            payment.paidAt?.substring(0, 10) ?? '',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ]),
      ]),
    );
  }
}
