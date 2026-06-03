import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/network/router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ApiClient().init();
  final savedLocale = await AppStorage.getLocale();

  final container = ProviderContainer(overrides: [
    localeProvider.overrideWith((ref) => Locale(savedLocale)),
  ]);

  // Pass container so notification taps can write to providers
  await NotificationService.init(container: container);

  runApp(UncontrolledProviderScope(container: container, child: const QuadroCloudApp()));
}

class QuadroCloudApp extends ConsumerWidget {
  const QuadroCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    // Navigate when a notification tap sets a pending route
    ref.listen(notificationPendingRouteProvider, (_, route) {
      if (route != null) {
        router.go(route);
        ref.read(notificationPendingRouteProvider.notifier).state = null;
      }
    });

    return MaterialApp.router(
      title: 'Quadro Cloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
