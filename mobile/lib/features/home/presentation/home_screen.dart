import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/home_repository.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quadro Cloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l.error, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => ref.invalidate(dashboardProvider), child: Text(l.retry)),
          ],
        )),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Overdue warning banner
                if (data.overdueCount > 0) ...[
                  _OverdueBanner(count: data.overdueCount),
                  const SizedBox(height: 16),
                ],

                // Next payment countdown card
                if (data.nextInvoice != null) ...[
                  _NextPaymentCard(invoice: data.nextInvoice!),
                  const SizedBox(height: 20),
                ],

                // Pending additional fees
                if (data.pendingFees.isNotEmpty) ...[
                  Text(l.pendingFees,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...data.pendingFees.map((fee) => _PendingFeeCard(fee: fee)),
                  const SizedBox(height: 20),
                ],

                // Quick action grid
                _QuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final int count;
  const _OverdueBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.danger, AppTheme.danger.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.overdue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(l.overdueWarning(count), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        TextButton(
          onPressed: () => context.go('/invoices'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(l.payNow),
        ),
      ]),
    );
  }
}

class _NextPaymentCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _NextPaymentCard({required this.invoice});

  Color _countdownColor(int days) {
    if (days <= 0) return AppTheme.danger;
    if (days <= 3) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final days = invoice['days_until_due'] as int? ?? 0;
    final amount = (invoice['amount'] as num).toDouble();
    final color = _countdownColor(days);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.nextPayment, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${amount.toStringAsFixed(0)} ج.م',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(
              days <= 0 ? l.dueToday : l.daysLeft(days),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Text(invoice['invoice_number'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.go('/invoices'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(l.payNow, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _PendingFeeCard extends StatelessWidget {
  final Map<String, dynamic> fee;
  const _PendingFeeCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final amount = (fee['amount'] as num).toDouble();
    final days = fee['days_until_due'] as int? ?? 0;
    final isUrgent = days <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUrgent ? AppTheme.warning.withValues(alpha: 0.5) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.attach_money, color: AppTheme.warning),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fee['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(fee['due_date'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${amount.toStringAsFixed(0)} ج.م',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(
            days <= 0 ? l.dueToday : l.daysLeft(days),
            style: TextStyle(color: isUrgent ? AppTheme.warning : Colors.grey, fontSize: 11),
          ),
        ]),
      ]),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ActionCard(icon: Icons.description_outlined, label: l.contracts, color: AppTheme.primary, onTap: () => context.go('/contracts')),
        _ActionCard(icon: Icons.receipt_outlined, label: l.invoices, color: const Color(0xFF059669), onTap: () => context.go('/invoices')),
        _ActionCard(icon: Icons.payment_outlined, label: l.paymentHistory, color: const Color(0xFF7C3AED), onTap: () => context.go('/payments')),
        _ActionCard(icon: Icons.headset_mic_outlined, label: l.support, color: const Color(0xFFD97706), onTap: () => context.go('/tickets')),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
