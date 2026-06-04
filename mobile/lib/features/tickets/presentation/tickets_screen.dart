import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../data/ticket_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.support),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.go('/tickets/new'),
          ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(ticketsProvider),
          retryLabel: l.retry,
        ),
        data: (tickets) => tickets.isEmpty
            ? EmptyState(
                icon: Icons.headset_mic_outlined,
                message: l.noTickets,
                actionLabel: l.newTicket,
                onAction: () => context.go('/tickets/new'),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(ticketsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: _TicketCard(ticket: tickets[i]),
                  ),
                ),
              ),
      ),
      floatingActionButton: ticketsAsync.hasValue && ticketsAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/tickets/new'),
              icon: const Icon(Icons.add),
              label: Text(l.newTicket),
            )
          : null,
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  Color _statusColor() {
    switch (ticket.status) {
      case 'open': return AppTheme.primary;
      case 'in_progress': return AppTheme.warning;
      default: return Colors.grey;
    }
  }

  Color _priorityColor() {
    switch (ticket.priority) {
      case 'high': return AppTheme.danger;
      case 'medium': return AppTheme.warning;
      default: return Colors.grey.shade400;
    }
  }

  String _priorityLabel() {
    switch (ticket.priority) {
      case 'high': return 'عاجل';
      case 'medium': return 'متوسط';
      default: return 'منخفض';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusColor = _statusColor();
    final priorityColor = _priorityColor();

    return PressableCard(
      onTap: () => context.go('/tickets/${ticket.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(right: BorderSide(color: priorityColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.support_agent_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _StatusChip(
                  label: ticket.status == 'open' ? l.open : ticket.status == 'in_progress' ? l.inProgress : l.closed,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                _PriorityDot(color: priorityColor, label: _priorityLabel()),
              ]),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
          ]),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final Color color;
  final String label;
  const _PriorityDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
