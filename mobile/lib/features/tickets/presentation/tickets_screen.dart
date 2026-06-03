import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../data/ticket_model.dart';
import '../../../core/theme/app_theme.dart';

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
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.go('/tickets/new'),
          ),
        ],
      ),
      body: ticketsAsync.when(
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
                onPressed: () => ref.invalidate(ticketsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
        data: (tickets) => tickets.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.headset_mic_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l.noTickets, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/tickets/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l.newTicket),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                ),
              ]))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(ticketsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
                ),
              ),
      ),
      floatingActionButton: ticketsAsync.hasValue && ticketsAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/tickets/new'),
              icon: const Icon(Icons.add),
              label: Text(l.newTicket),
              backgroundColor: AppTheme.primary,
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
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.support_agent, color: _statusColor()),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status == 'open' ? l.open : ticket.status == 'in_progress' ? l.inProgress : l.closed,
                    style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _priorityColor(), shape: BoxShape.circle),
                ),
              ]),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
