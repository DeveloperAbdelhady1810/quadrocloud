import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(ticketRepositoryProvider).reply(widget.ticketId, text);
      _msgCtrl.clear();
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      // Scroll to bottom after reply
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('تذكرة #${widget.ticketId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => ErrorState(
          message: l.error,
          onRetry: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
          retryLabel: l.retry,
        ),
        data: (ticket) => Column(children: [

          // ── Ticket info header ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: ticket.status, l: l),
            ]),
          ),

          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: ticket.messages.isEmpty
                ? Center(child: Text('لا توجد رسائل بعد', style: TextStyle(color: Colors.grey.shade400)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: ticket.messages.length,
                    itemBuilder: (_, i) {
                      final msg = ticket.messages[i];
                      return AnimatedListItem(
                        index: i,
                        msPerItem: 30,
                        child: _MessageBubble(
                          message: msg.message,
                          isAdmin: msg.isAdmin,
                          time: msg.createdAt,
                        ),
                      );
                    },
                  ),
          ),

          // ── Reply input ───────────────────────────────────────────────────
          if (ticket.status != 'closed')
            _ReplyInput(
              controller: _msgCtrl,
              sending: _sending,
              onSend: _reply,
              hintText: l.message,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(l.ticketClosed, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l;
  const _StatusBadge({required this.status, required this.l});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'open':
        color = AppTheme.primary; label = l.open;
      case 'in_progress':
        color = AppTheme.warning; label = l.inProgress;
      default:
        color = Colors.grey; label = l.closed;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String hintText;
  const _ReplyInput({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: false,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: sending
                  ? null
                  : const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: sending ? Colors.grey.shade200 : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.white : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isAdmin ? Radius.zero : const Radius.circular(18),
                  bottomRight: isAdmin ? const Radius.circular(18) : Radius.zero,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isAdmin ? AppTheme.textPrimary : Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time.length > 10 ? time.substring(0, 16) : time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isAdmin ? Colors.grey.shade400 : Colors.white60,
                  ),
                ),
              ]),
            ),
          ),
          if (!isAdmin) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
