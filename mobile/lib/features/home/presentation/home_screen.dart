import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/home_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.retry,
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(dashboardProvider),
          retryLabel: l.retry,
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Overdue warning banner
                if (data.overdueCount > 0) ...[
                  AnimatedListItem(index: 0, child: _OverdueBanner(count: data.overdueCount)),
                  const SizedBox(height: 16),
                ],

                // Next payment countdown card
                if (data.nextInvoice != null) ...[
                  AnimatedListItem(index: 1, child: _NextPaymentCard(invoice: data.nextInvoice!)),
                  const SizedBox(height: 24),
                ],

                // Pending additional fees
                if (data.pendingFees.isNotEmpty) ...[
                  AnimatedListItem(
                    index: 2,
                    child: _SectionHeader(icon: Icons.schedule_rounded, title: l.pendingFees),
                  ),
                  const SizedBox(height: 12),
                  ...data.pendingFees.asMap().entries.map((e) =>
                    AnimatedListItem(index: e.key + 3, child: _PendingFeeCard(fee: e.value)),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quick action grid
                AnimatedListItem(
                  index: data.pendingFees.length + 3,
                  child: _SectionHeader(icon: Icons.apps_rounded, title: 'الوصول السريع'),
                ),
                const SizedBox(height: 12),
                AnimatedListItem(
                  index: data.pendingFees.length + 4,
                  child: _QuickActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 17, color: AppTheme.primary),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    ]);
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.overdue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          Text(l.overdueWarning(count), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => context.go('/invoices'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(l.payNow, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.nextPayment, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(
              days <= 0 ? l.dueToday : l.daysLeft(days),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          '${amount.toStringAsFixed(0)} ج.م',
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1),
        ),
        const SizedBox(height: 8),
        Text(invoice['invoice_number'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 20),
        PressableCard(
          onTap: () => context.go('/invoices'),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(l.payNow, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
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
    final days = fee['days_until_due'].toInt() as int? ?? 0;
    final isUrgent = days <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? AppTheme.warning.withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: (isUrgent ? AppTheme.warning : AppTheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.attach_money_rounded, color: isUrgent ? AppTheme.warning : AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fee['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(fee['due_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${amount.toStringAsFixed(0)} ج.م',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            days <= 0 ? l.dueToday : l.daysLeft(days),
            style: TextStyle(
              color: isUrgent ? AppTheme.warning : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
      childAspectRatio: 1.55,
      children: [
        _ActionCard(
          icon: Icons.description_outlined,
          label: l.contracts,
          color: AppTheme.primary,
          onTap: () => context.go('/contracts'),
        ),
        _ActionCard(
          icon: Icons.receipt_outlined,
          label: l.invoices,
          color: const Color(0xFF059669),
          onTap: () => context.go('/invoices'),
        ),
        _ActionCard(
          icon: Icons.payment_outlined,
          label: l.paymentHistory,
          color: const Color(0xFF7C3AED),
          onTap: () => context.go('/payments'),
        ),
        _ActionCard(
          icon: Icons.headset_mic_outlined,
          label: l.support,
          color: const Color(0xFFD97706),
          onTap: () => context.go('/tickets'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.12),
                widget.color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(color: widget.color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
