import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/explore_repository.dart';
import '../data/post_model.dart';
import '../data/service_model.dart';
import '../../community/data/community_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabIndex = ref.read(notificationExploreTabProvider);
      if (tabIndex != _tab.index) _tab.animateTo(tabIndex);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    ref.listen(notificationExploreTabProvider, (_, tabIdx) {
      if (_tab.index != tabIdx) _tab.animateTo(tabIdx);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.explore),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Icons.newspaper_outlined), text: l.news),
            Tab(icon: const Icon(Icons.grid_view_rounded), text: l.ourServices),
            const Tab(icon: Icon(Icons.people_outline_rounded), text: 'العملاء'),
            const Tab(icon: Icon(Icons.emoji_events_outlined), text: 'الترتيب'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_NewsTab(), _ServicesTab(), _ClientsTab(), _LeaderboardTab()],
      ),
    );
  }
}

// ─── News Tab ─────────────────────────────────────────────────────────────────

class _NewsTab extends ConsumerWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final postsAsync = ref.watch(postsProvider);
    return postsAsync.when(
      loading: () => const ShimmerPostList(count: 4),
      error: (e, _) => ErrorState(
        message: l.error,
        onRetry: () => ref.invalidate(postsProvider),
        retryLabel: l.retry,
      ),
      data: (posts) => posts.isEmpty
          ? EmptyState(icon: Icons.newspaper_outlined, message: l.noNews)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(postsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (_, i) => AnimatedListItem(
                  index: i,
                  child: _PostCard(post: posts[i]),
                ),
              ),
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (post.mediaPath != null && post.mediaType == 'image')
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              '${AppConstants.storageUrl}/${post.mediaPath}',
              height: 180, width: double.infinity, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: const Color(0xFFF1F5F9),
                child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              post.content.length > 120 ? '${post.content.substring(0, 120)}...' : post.content,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.6, fontSize: 13),
            ),
            if (post.publishedAt != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  post.publishedAt!.substring(0, 10),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Services Tab ─────────────────────────────────────────────────────────────

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final servicesAsync = ref.watch(servicesProvider);
    final highlightId = ref.watch(notificationHighlightServiceProvider);
    return servicesAsync.when(
      loading: () => const ShimmerList(count: 4),
      error: (e, _) => ErrorState(
        message: l.error,
        onRetry: () => ref.invalidate(servicesProvider),
        retryLabel: l.retry,
      ),
      data: (services) => services.isEmpty
          ? EmptyState(icon: Icons.grid_view_rounded, message: l.noServices)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(servicesProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (_, i) => AnimatedListItem(
                  index: i,
                  child: _ServiceCard(
                    service: services[i],
                    highlighted: highlightId == services[i].id,
                  ),
                ),
              ),
            ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final bool highlighted;
  const _ServiceCard({required this.service, this.highlighted = false});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    if (widget.highlighted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _pulseCtrl.repeat(count: 3);
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceRequestSheet(service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: widget.highlighted ? Border.all(color: AppTheme.primary, width: 2) : null,
          boxShadow: [
            if (widget.highlighted)
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
            else
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Service icon in container
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: widget.service.icon != null
                      ? Text(widget.service.icon!, style: const TextStyle(fontSize: 26))
                      : const Icon(Icons.miscellaneous_services_outlined, color: AppTheme.primary, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.service.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
                if (widget.service.showPrice && widget.service.price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.service.price!.toStringAsFixed(0)} ج.م / شهر',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ])),
            ]),
            if (widget.service.description != null) ...[
              const SizedBox(height: 12),
              Text(widget.service.description!,
                  style: const TextStyle(color: AppTheme.textSecondary, height: 1.6, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            PressableCard(
              onTap: () => _showRequestDialog(context),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.send_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('طلب الخدمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Service request sheet ────────────────────────────────────────────────────

class _ServiceRequestSheet extends ConsumerStatefulWidget {
  final ServiceModel service;
  const _ServiceRequestSheet({required this.service});
  @override
  ConsumerState<_ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends ConsumerState<_ServiceRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(exploreRepositoryProvider).requestService(
        serviceId: widget.service.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
      );
      setState(() => _sent = true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _sent ? _SuccessView(onClose: () => Navigator.pop(context)) : _FormView(
        formKey: _formKey,
        service: widget.service,
        nameCtrl: _nameCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
        msgCtrl: _msgCtrl,
        loading: _loading,
        onSubmit: _submit,
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 36),
      ),
      const SizedBox(height: 16),
      const Text('تم إرسال طلبك بنجاح!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      Text('سنتواصل معك قريباً', style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: onClose, child: const Text('إغلاق')),
    ]);
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final ServiceModel service;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl, msgCtrl;
  final bool loading;
  final VoidCallback onSubmit;
  const _FormView({
    required this.formKey, required this.service,
    required this.nameCtrl, required this.emailCtrl,
    required this.phoneCtrl, required this.msgCtrl,
    required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Sheet handle
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          if (service.icon != null)
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(service.icon!, style: const TextStyle(fontSize: 22))),
            ),
          if (service.icon != null) const SizedBox(width: 10),
          Expanded(child: Text(
            'طلب: ${service.name}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          )),
        ]),
        const SizedBox(height: 20),
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'رسالتك (اختياري)'),
        ),
        const SizedBox(height: 20),
        PressableCard(
          onTap: loading ? () {} : onSubmit,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Clients Tab ──────────────────────────────────────────────────────────────

class _ClientsTab extends ConsumerStatefulWidget {
  const _ClientsTab();
  @override
  ConsumerState<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends ConsumerState<_ClientsTab> {
  // Local optimistic follow state
  final Map<int, bool> _followingOverride = {};

  Future<void> _toggle(int clientId, bool currentlyFollowing) async {
    setState(() => _followingOverride[clientId] = !currentlyFollowing);
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(clientId);
      } else {
        await repo.follow(clientId);
      }
      ref.invalidate(ourClientsProvider);
    } catch (_) {
      setState(() => _followingOverride[clientId] = currentlyFollowing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ourClientsProvider);
    return async.when(
      loading: () => const ShimmerList(count: 6),
      error: (e, _) => ErrorState(
        message: 'تعذر التحميل',
        onRetry: () => ref.invalidate(ourClientsProvider),
        retryLabel: 'إعادة المحاولة',
      ),
      data: (clients) => clients.isEmpty
          ? const EmptyState(icon: Icons.people_outline_rounded, message: 'لا يوجد عملاء بعد')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(ourClientsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: clients.length,
                itemBuilder: (_, i) {
                  final c = clients[i];
                  final following = _followingOverride[c.id] ?? c.isFollowing;
                  final medalColor = c.rank == 1
                      ? AppTheme.gold
                      : c.rank == 2
                          ? AppTheme.silver
                          : c.rank == 3
                              ? AppTheme.bronze
                              : AppTheme.primary;

                  return AnimatedListItem(
                    index: i,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        PressableCard(
                          onTap: () => context.go('/community/clients/${c.id}'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: medalColor.withValues(alpha: 0.15),
                            child: Text(c.name.substring(0, 1),
                                style: TextStyle(fontWeight: FontWeight.w800, color: medalColor)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/community/clients/${c.id}'),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (c.company != null)
                                Text(c.company!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              Text('${c.contractsCount} عقد · ${c.score} نقطة',
                                  style: TextStyle(fontSize: 11, color: medalColor, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        if (!c.isMe)
                          GestureDetector(
                            onTap: () => _toggle(c.id, following),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: following ? Colors.transparent : AppTheme.primary,
                                border: following ? Border.all(color: AppTheme.primary) : null,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                following ? 'متابَع' : 'متابعة',
                                style: TextStyle(
                                  color: following ? AppTheme.primary : Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);
    return async.when(
      loading: () => const ShimmerList(count: 8),
      error: (e, _) => ErrorState(
        message: 'تعذر التحميل',
        onRetry: () => ref.invalidate(leaderboardProvider),
        retryLabel: 'إعادة المحاولة',
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(leaderboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // My rank banner
            if (data.myRank != null) ...[
              AnimatedListItem(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ترتيبك', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text('#${data.myRank}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('نقاطك', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text('${data.myScore}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ),
              ),
            ],

            // Entries
            ...data.entries.asMap().entries.map((e) {
              final entry   = e.value;
              final color   = entry.medal == 'gold'
                  ? AppTheme.gold
                  : entry.medal == 'silver'
                      ? AppTheme.silver
                      : entry.medal == 'bronze'
                          ? AppTheme.bronze
                          : AppTheme.textSecondary;
              final emoji = entry.medal == 'gold' ? '🥇' : entry.medal == 'silver' ? '🥈' : entry.medal == 'bronze' ? '🥉' : '';

              return AnimatedListItem(
                index: e.key + 1,
                child: GestureDetector(
                  onTap: () => context.go('/community/clients/${entry.clientId}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: entry.isGold ? AppTheme.gold.withValues(alpha: 0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: entry.isGold
                            ? AppTheme.gold.withValues(alpha: 0.4)
                            : entry.isMe
                                ? AppTheme.primary.withValues(alpha: 0.3)
                                : const Color(0xFFF1F5F9),
                      ),
                      boxShadow: entry.isGold
                          ? [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          emoji.isNotEmpty ? emoji : '#${entry.rank}',
                          style: emoji.isNotEmpty
                              ? const TextStyle(fontSize: 20)
                              : TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(entry.displayName.substring(0, 1),
                            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Flexible(child: Text(entry.displayName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                            if (entry.isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                                child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          if (entry.company != null)
                            Text(entry.company!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${entry.score}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
                        const Text('نقطة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                      ]),
                      if (entry.isGold) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(8)),
                          child: const Text('خصم 5%',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
