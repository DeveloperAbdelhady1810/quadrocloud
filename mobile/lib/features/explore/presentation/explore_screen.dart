import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/explore_repository.dart';
import '../data/post_model.dart';
import '../data/service_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    // Jump to the tab requested by a notification tap
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

    // React to future notification taps while screen is open
    ref.listen(notificationExploreTabProvider, (_, tabIdx) {
      if (_tab.index != tabIdx) _tab.animateTo(tabIdx);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.explore),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: const Icon(Icons.newspaper_outlined), text: l.news),
            Tab(icon: const Icon(Icons.grid_view_rounded), text: l.ourServices),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _NewsTab(),
          _ServicesTab(),
        ],
      ),
    );
  }
}

// ─── News Tab ────────────────────────────────────────────────────────────────

class _NewsTab extends ConsumerWidget {
  const _NewsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final postsAsync = ref.watch(postsProvider);
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.error)),
      data: (posts) => posts.isEmpty
          ? Center(child: Text(l.noNews, style: const TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(postsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (_, i) => _AnimatedPostCard(post: posts[i], index: i),
              ),
            ),
    );
  }
}

class _AnimatedPostCard extends StatefulWidget {
  final PostModel post;
  final int index;
  const _AnimatedPostCard({required this.post, required this.index});
  @override
  State<_AnimatedPostCard> createState() => _AnimatedPostCardState();
}

class _AnimatedPostCardState extends State<_AnimatedPostCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _PostCard(post: widget.post),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (post.mediaPath != null && post.mediaType == 'image')
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              '${AppConstants.storageUrl}/${post.mediaPath}',
              height: 180, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              post.content.length > 120 ? '${post.content.substring(0, 120)}...' : post.content,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13),
            ),
            if (post.publishedAt != null) ...[
              const SizedBox(height: 8),
              Text(post.publishedAt!.substring(0, 10), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.error)),
      data: (services) => services.isEmpty
          ? Center(child: Text(l.noServices, style: const TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(servicesProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (_, i) => _AnimatedServiceCard(
                  service: services[i],
                  index: i,
                  highlighted: highlightId == services[i].id,
                ),
              ),
            ),
    );
  }
}

class _AnimatedServiceCard extends StatefulWidget {
  final ServiceModel service;
  final int index;
  final bool highlighted;
  const _AnimatedServiceCard({required this.service, required this.index, this.highlighted = false});
  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _fadeCtrl.forward();
    });

    if (widget.highlighted) {
      Future.delayed(Duration(milliseconds: widget.index * 80 + 600), () {
        if (mounted) _pulseCtrl.repeat(count: 3);
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _pulse,
          child: _ServiceCard(service: widget.service, highlighted: widget.highlighted),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool highlighted;
  const _ServiceCard({required this.service, this.highlighted = false});

  void _showRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceRequestSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? Border.all(color: AppTheme.primary, width: 2.5)
            : null,
        boxShadow: [
          if (highlighted)
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2)
          else
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (service.icon != null)
              Text(service.icon!, style: const TextStyle(fontSize: 32)),
            if (service.icon != null) const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (service.showPrice && service.price != null)
                Text('${service.price!.toStringAsFixed(0)} ج.م / شهر',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ])),
          ]),
          if (service.description != null) ...[
            const SizedBox(height: 10),
            Text(service.description!, style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRequestDialog(context),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('طلب الخدمة'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
        ]),
      ),
    );
  }
}

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
        name:      _nameCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim(),
        message:   _msgCtrl.text.trim(),
      );
      setState(() => _sent = true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    } finally {
      setState(() => _loading = false);
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
      const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 64),
      const SizedBox(height: 16),
      const Text('تم إرسال طلبك بنجاح!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('سنتواصل معك قريباً', style: TextStyle(color: Colors.grey.shade600)),
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
  const _FormView({required this.formKey, required this.service, required this.nameCtrl, required this.emailCtrl, required this.phoneCtrl, required this.msgCtrl, required this.loading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (service.icon != null) Text(service.icon!, style: const TextStyle(fontSize: 24)),
          if (service.icon != null) const SizedBox(width: 8),
          Text('طلب: ${service.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 20),
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'رسالتك (اختياري)')),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
            child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('إرسال الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
