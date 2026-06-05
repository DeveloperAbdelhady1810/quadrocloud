import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/contract_repository.dart';
import '../data/contract_model.dart';
import '../../invoices/data/invoice_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class ContractDetailScreen extends ConsumerStatefulWidget {
  final int contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  bool _paying = false;

  ContractModel? _findContract(List<ContractModel> contracts) {
    try {
      return contracts.firstWhere((c) => c.id == widget.contractId);
    } catch (_) {
      return null;
    }
  }

  String _cycleLabel(String cycle, AppLocalizations l) {
    switch (cycle) {
      case 'monthly': return l.monthly;
      case 'quarterly': return l.quarterly;
      case 'annually': return l.annually;
      default: return cycle;
    }
  }

  Color _daysColor(int days) {
    if (days <= 0) return AppTheme.danger;
    if (days <= 5) return AppTheme.warning;
    return AppTheme.success;
  }

  Future<void> _pay(BuildContext context, ContractModel contract) async {
    if (_paying || contract.unpaidInvoiceId == null) return;
    setState(() => _paying = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final result = await ref.read(invoiceRepositoryProvider).initiatePayment(contract.unpaidInvoiceId!);
      if (mounted) {
        router.go(
          '/invoices/pay/${contract.unpaidInvoiceId}/${Uri.encodeComponent(result.paymentUrl)}'
          '?orderId=${Uri.encodeComponent(result.paymobOrderId)}',
        );
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('فشل الاتصال بنظام الدفع، حاول مجدداً')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(l.contracts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(contractsProvider),
          ),
        ],
      ),
      body: contractsAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(contractsProvider),
          retryLabel: l.retry,
        ),
        data: (contracts) {
          final contract = _findContract(contracts);
          if (contract == null) {
            return const Center(child: Text('لم يتم العثور على العقد'));
          }
          return _ContractDetailBody(
            contract: contract,
            cycleLabel: _cycleLabel(contract.billingCycle, l),
            daysColor: _daysColor(contract.daysUntilDue),
            paying: _paying,
            onPay: () => _pay(context, contract),
            l: l,
          );
        },
      ),
    );
  }
}

class _ContractDetailBody extends StatelessWidget {
  final ContractModel contract;
  final String cycleLabel;
  final Color daysColor;
  final bool paying;
  final VoidCallback onPay;
  final AppLocalizations l;

  const _ContractDetailBody({
    required this.contract,
    required this.cycleLabel,
    required this.daysColor,
    required this.paying,
    required this.onPay,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final c = contract;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Header card ────────────────────────────────────────────────────────
        AnimatedListItem(
          index: 0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    _WhiteChip(label: cycleLabel),
                    const SizedBox(width: 6),
                    if (c.status == 'active') const _WhiteChip(label: 'نشط', isSuccess: true),
                  ]),
                ])),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الرسوم', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${c.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                ]),
                if (c.nextDueDate != null)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('الاستحقاق القادم', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(c.nextDueDate!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
              ]),
            ]),
          ),
        ),

        // ── Due countdown ──────────────────────────────────────────────────────
        AnimatedListItem(
          index: 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: daysColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: daysColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.access_time_rounded, color: daysColor, size: 20),
              const SizedBox(width: 12),
              Text(
                c.daysUntilDue <= 0 ? l.dueToday : l.daysLeft(c.daysUntilDue),
                style: TextStyle(color: daysColor, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              if (c.gracePeriodDays > 0)
                Text('فترة السماح: ${c.gracePeriodDays} يوم',
                    style: TextStyle(color: daysColor.withValues(alpha: 0.7), fontSize: 12)),
            ]),
          ),
        ),

        // ── Contract dates ─────────────────────────────────────────────────────
        AnimatedListItem(
          index: 2,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              if (c.startDate != null)
                _DetailRow(icon: Icons.play_circle_outline_rounded, label: 'تاريخ البداية', value: c.startDate!),
              if (c.endDate != null)
                _DetailRow(icon: Icons.stop_circle_outlined, label: 'تاريخ الانتهاء', value: c.endDate!),
              _DetailRow(
                icon: Icons.repeat_rounded,
                label: 'دورة الفوترة',
                value: cycleLabel,
                isLast: c.nextDueDate == null,
              ),
              if (c.nextDueDate != null)
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'الاستحقاق القادم',
                  value: c.nextDueDate!,
                  valueColor: daysColor,
                  isLast: true,
                ),
            ]),
          ),
        ),

        // ── Pay button ─────────────────────────────────────────────────────────
        if (c.canPay)
          AnimatedListItem(
            index: 3,
            child: PressableCard(
              onTap: paying ? () {} : onPay,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: paying
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.payment_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'ادفع ${c.payableAmount!.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WhiteChip extends StatelessWidget {
  final String label;
  final bool isSuccess;
  const _WhiteChip({required this.label, this.isSuccess = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF16A34A).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
