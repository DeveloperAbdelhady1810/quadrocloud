import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/explore')) return 1;
    if (loc.startsWith('/contracts')) return 2;
    if (loc.startsWith('/invoices') || loc.startsWith('/payments')) return 3;
    if (loc.startsWith('/tickets')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(children: [
        const _OfflineBanner(),
        Expanded(child: child),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/explore'); break;
            case 2: context.go('/contracts'); break;
            case 3: context.go('/invoices'); break;
            case 4: context.go('/tickets'); break;
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.home),
          NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: l.explore),
          NavigationDestination(icon: const Icon(Icons.description_outlined), selectedIcon: const Icon(Icons.description), label: l.contracts),
          NavigationDestination(icon: const Icon(Icons.receipt_outlined), selectedIcon: const Icon(Icons.receipt), label: l.invoices),
          NavigationDestination(icon: const Icon(Icons.headset_mic_outlined), selectedIcon: const Icon(Icons.headset_mic), label: l.support),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatefulWidget {
  const _OfflineBanner();

  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _height;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _height = Tween<double>(begin: 0, end: 36)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(seconds: 3), _check);
  }

  Future<void> _check() async {
    if (!mounted) return;
    bool isOnline;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      isOnline = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      isOnline = false;
    }

    if (!mounted) return;
    if (!isOnline && !_offline) {
      setState(() => _offline = true);
      _ctrl.forward();
    } else if (isOnline && _offline) {
      setState(() => _offline = false);
      _ctrl.reverse();
    }
    Future.delayed(const Duration(seconds: 6), _check);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _height,
      builder: (_, __) {
        if (_height.value <= 0) return const SizedBox.shrink();
        return SizedBox(
          height: _height.value,
          child: Container(
            color: const Color(0xFF1A1A2E),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14),
              const SizedBox(width: 6),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
