import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../../../core/theme/app_theme.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(ticketRepositoryProvider).reply(widget.ticketId, _msgCtrl.text.trim());
      _msgCtrl.clear();
      ref.invalidate(ticketDetailProvider(widget.ticketId));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text('تذكرة #${widget.ticketId}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(ticketDetailProvider(widget.ticketId))),
        ],
      ),
      body: ticketAsync.when(
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
                onPressed: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
        data: (ticket) => Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(children: [
              Expanded(child: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.status == 'closed' ? Colors.grey.shade100 : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ticket.status == 'open' ? l.open : ticket.status == 'in_progress' ? l.inProgress : l.closed,
                  style: TextStyle(fontSize: 12, color: ticket.status == 'closed' ? Colors.grey : AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ticket.messages.length,
              itemBuilder: (_, i) {
                final msg = ticket.messages[i];
                return _MessageBubble(message: msg.message, isAdmin: msg.isAdmin, time: msg.createdAt);
              },
            ),
          ),

          // Reply input
          if (ticket.status != 'closed')
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: l.message,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _sending ? null : _reply,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade50,
              child: Text(l.ticketClosed, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
            ),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isAdmin;
  final String time;
  const _MessageBubble({required this.message, required this.isAdmin, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.support_agent, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.white : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isAdmin ? Radius.zero : const Radius.circular(18),
                  bottomRight: isAdmin ? const Radius.circular(18) : Radius.zero,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(message, style: TextStyle(color: isAdmin ? const Color(0xFF1A1A2E) : Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time.length > 10 ? time.substring(0, 16) : time,
                    style: TextStyle(fontSize: 10, color: isAdmin ? Colors.grey : Colors.white70)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
