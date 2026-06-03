import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/contract_repository.dart';
import '../data/contract_model.dart';
import '../../../core/theme/app_theme.dart';
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
                onPressed: () => ref.invalidate(contractsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
        data: (contracts) => contracts.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l.noContracts, style: const TextStyle(color: Colors.grey)),
              ]))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(contractsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contracts.length,
                  itemBuilder: (_, i) => _ContractCard(contract: contracts[i]),
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
      case 'monthly':   return l.monthly;
      case 'quarterly': return l.quarterly;
      case 'annually':  return l.annually;
      default:          return cycle;
    }
  }

  Future<void> _pay(BuildContext context) async {
    if (_paying || widget.contract.unpaidInvoiceId == null) return;
    setState(() => _paying = true);
    // Capture before async gap
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    String? url;
    try {
      url = await ref
          .read(invoiceRepositoryProvider)
          .initiatePayment(widget.contract.unpaidInvoiceId!);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('فشل الاتصال بنظام الدفع، حاول مجدداً')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
    if (url != null && mounted) {
      router.go(
        '/invoices/pay/${widget.contract.unpaidInvoiceId}/${Uri.encodeComponent(url)}',
      );
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_cycleLabel(c.billingCycle, l),
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                if (c.status == 'active')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(l.active,
                        style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ])),
            Text('${c.price.toStringAsFixed(0)} ج.م',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
          ]),
        ),

        // ── Due date footer ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: showPay
                ? BorderRadius.zero
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l.dueDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Row(children: [
              Text(c.nextDueDate ?? '',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
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

        // ── Pay button (only when canPay) ────────────────────────────────────
        if (showPay)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: InkWell(
                onTap: _paying ? null : () => _pay(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, const Color(0xFF6366F1)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: _paying
                      ? const Center(
                          child: SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.payment_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'ادفع ${c.payableAmount!.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'يشمل 5 ج.م رسوم Paymob',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
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
