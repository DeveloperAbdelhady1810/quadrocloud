import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: child,
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
