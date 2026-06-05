import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../data/ticket_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TicketModel> _applyFilters(List<TicketModel> tickets) {
    var list = tickets;
    if (_statusFilter != 'all') list = list.where((t) => t.status == _statusFilter).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
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
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyState(
              icon: Icons.headset_mic_outlined,
              message: l.noTickets,
              actionLabel: l.newTicket,
              onAction: () => context.go('/tickets/new'),
            );
          }
          final filtered = _applyFilters(tickets);
          return Column(children: [

            // ── Search + filter bar ──────────────────────────────────────────
            _SearchFilterBar(
              controller: _searchCtrl,
              filter: _statusFilter,
              onFilterChanged: (v) => setState(() => _statusFilter = v),
              onSearchChanged: (_) => setState(() {}),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(ticketsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => AnimatedListItem(
                          index: i,
                          child: _TicketCard(ticket: filtered[i]),
                        ),
                      ),
                    ),
            ),
          ]);
        },
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

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const _SearchFilterBar({
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'ابحث بعنوان التذكرة...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, v, __) => v.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FilterChip(label: 'الكل', value: 'all', selected: filter, onTap: onFilterChanged),
            const SizedBox(width: 8),
            _FilterChip(label: 'مفتوحة', value: 'open', selected: filter, onTap: onFilterChanged, color: AppTheme.primary),
            const SizedBox(width: 8),
            _FilterChip(label: 'قيد المعالجة', value: 'in_progress', selected: filter, onTap: onFilterChanged, color: AppTheme.warning),
            const SizedBox(width: 8),
            _FilterChip(label: 'مغلقة', value: 'closed', selected: filter, onTap: onFilterChanged, color: Colors.grey),
          ]),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
