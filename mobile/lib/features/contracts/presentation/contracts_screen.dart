import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/contract_repository.dart';
import '../data/contract_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../invoices/data/invoice_repository.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.contracts)),
      body: contractsAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(contractsProvider),
          retryLabel: l.retry,
        ),
        data: (contracts) => contracts.isEmpty
            ? EmptyState(icon: Icons.description_outlined, message: l.noContracts)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(contractsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contracts.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: PressableCard(
                      onTap: () => context.go('/contracts/${contracts[i].id}'),
                      child: _ContractCard(contract: contracts[i]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ContractCard extends ConsumerStatefulWidget {
  final ContractModel contract;
  const _ContractCard({required this.contract});

  @override
  ConsumerState<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends ConsumerState<_ContractCard> {
  bool _paying = false;

  Color _daysColor(int days) {
    if (days <= 0) return AppTheme.danger;
    if (days <= 5) return AppTheme.warning;
    return AppTheme.success;
  }

  String _cycleLabel(String cycle, AppLocalizations l) {
    switch (cycle) {
      case 'monthly': return l.monthly;
      case 'quarterly': return l.quarterly;
      case 'annually': return l.annually;
      default: return cycle;
    }
  }

  Future<void> _pay(BuildContext context) async {
    if (_paying || widget.contract.unpaidInvoiceId == null) return;
    setState(() => _paying = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    String? url;
    try {
      url = await ref
          .read(invoiceRepositoryProvider)
          .initiatePayment(widget.contract.unpaidInvoiceId!);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('فشل الاتصال بنظام الدفع، حاول مجدداً')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
    if (url != null && mounted) {
      router.go('/invoices/pay/${widget.contract.unpaidInvoiceId}/${Uri.encodeComponent(url)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = widget.contract;
    final color = _daysColor(c.daysUntilDue);
    final showPay = c.canPay;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(children: [

        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.15), AppTheme.primary.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Row(children: [
                _Chip(label: _cycleLabel(c.billingCycle, l), color: AppTheme.primary),
                if (c.status == 'active') ...[
                  const SizedBox(width: 6),
                  _Chip(label: l.active, color: AppTheme.success),
                ],
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                c.price.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary),
              ),
              const Text('ج.م', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ]),
        ),

        // ── Due date footer ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            border: Border(top: BorderSide(color: color.withValues(alpha: 0.12))),
            borderRadius: showPay
                ? BorderRadius.zero
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(l.dueDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
            Row(children: [
              Text(c.nextDueDate ?? '', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  c.daysUntilDue <= 0 ? l.dueToday : l.daysLeft(c.daysUntilDue),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ]),
        ),

        // ── Pay button ────────────────────────────────────────────────────────
        if (showPay)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _paying ? null : () => _pay(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                    ),
                  ),
                  child: _paying
                      ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.payment_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'ادفع ${c.payableAmount!.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('يشمل 5 ج.م رسوم Paymob',
                                style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ),
                        ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
