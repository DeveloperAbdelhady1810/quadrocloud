import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../data/notification_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const ShimmerList(count: 6),
        error: (e, _) => ErrorState(
          message: 'حدث خطأ في تحميل الإشعارات',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) => notifications.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                message: 'لا توجد إشعارات بعد',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: _NotificationCard(notification: notifications[i]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  IconData _typeIcon() {
    switch (notification.type) {
      case 'invoice': return Icons.receipt_outlined;
      case 'payment': return Icons.payment_outlined;
      case 'contract': return Icons.description_outlined;
      case 'ticket': return Icons.headset_mic_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _typeColor() {
    switch (notification.type) {
      case 'invoice': return AppTheme.warning;
      case 'payment': return AppTheme.success;
      case 'contract': return AppTheme.primary;
      case 'ticket': return const Color(0xFF7C3AED);
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(), color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            notification.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
          ),
          if (notification.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            notification.createdAt,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ])),
        const SizedBox(width: 8),
        Container(
          width: 8, height: 8,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: notification.sent ? AppTheme.success : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
      ]),
    );
  }
}
