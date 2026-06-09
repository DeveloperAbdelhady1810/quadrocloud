import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/community_repository.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  final int clientId;
  const ClientProfileScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool _followLoading = false;

  Future<void> _toggleFollow(Map<String, dynamic> profile) async {
    setState(() => _followLoading = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final following = profile['is_following'] as bool;
      if (following) {
        await repo.unfollow(widget.clientId);
      } else {
        await repo.follow(widget.clientId);
      }
      ref.invalidate(clientProfileProvider(widget.clientId));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(clientProfileProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: profileAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => ErrorState(
          message: 'تعذر تحميل الملف الشخصي',
          onRetry: () => ref.invalidate(clientProfileProvider(widget.clientId)),
        ),
        data: (profile) {
          final isMe      = profile['is_me'] as bool;
          final following = profile['is_following'] as bool;
          final rank      = profile['rank'] as int?;
          final score     = profile['score'] as int;
          final medal     = rank == 1 ? AppTheme.gold : rank == 2 ? AppTheme.silver : rank == 3 ? AppTheme.bronze : AppTheme.primary;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // Avatar + name header
              AnimatedListItem(
                index: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [medal.withValues(alpha: 0.15), medal.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: medal.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: medal.withValues(alpha: 0.2),
                      child: Text(
                        (profile['public_name'] as String).substring(0, 1),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: medal),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(profile['public_name'] as String,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    if (profile['public_company'] != null) ...[
                      const SizedBox(height: 4),
                      Text(profile['public_company'] as String,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                    if (rank != null && rank <= 3) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(color: medal, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          rank == 1 ? '🥇 المركز الأول' : rank == 2 ? '🥈 المركز الثاني' : '🥉 المركز الثالث',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Stats row
              AnimatedListItem(
                index: 1,
                child: Row(children: [
                  _StatBox(label: 'النقاط', value: score.toString(), color: medal),
                  const SizedBox(width: 10),
                  _StatBox(label: 'العقود', value: profile['contracts_count'].toString(), color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatBox(label: 'المتابِعون', value: profile['followers_count'].toString(), color: AppTheme.success),
                ]),
              ),

              const SizedBox(height: 20),

              // Follow button (hidden for own profile)
              if (!isMe)
                AnimatedListItem(
                  index: 2,
                  child: PressableCard(
                    onTap: _followLoading ? () {} : () => _toggleFollow(profile),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: following
                            ? null
                            : const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
                        color: following ? null : null,
                        border: following ? Border.all(color: AppTheme.primary) : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _followLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text(
                                following ? 'إلغاء المتابعة' : 'متابعة',
                                style: TextStyle(
                                  color: following ? AppTheme.primary : Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}
