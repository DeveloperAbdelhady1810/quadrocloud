import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

// ─── Deep-link state providers ────────────────────────────────────────────────

/// Which explore tab to open: 0 = news, 1 = services
final notificationExploreTabProvider = StateProvider<int>((ref) => 0);

/// Service ID to highlight when opening the services tab
final notificationHighlightServiceProvider = StateProvider<int?>((ref) => null);

/// Pending route from a notification tap (set before navigation happens)
final notificationPendingRouteProvider = StateProvider<String?>((ref) => null);

// ─── Background handler (top-level, required by Firebase) ────────────────────

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {}

// ─── Service ─────────────────────────────────────────────────────────────────

class NotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'quadro_cloud_high';
  static const _channelName = 'Quadro Cloud';

  static ProviderContainer? _container;

  /// Call once at app start, pass the ProviderContainer so we can write providers.
  static Future<void> init({ProviderContainer? container}) async {
    _container = container;
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    if (Platform.isAndroid) {
      await _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId, _channelName, importance: Importance.high));
    }

    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showLocal);
    }

    // App opened by tapping a notification (was in background/suspended)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Call after app fully loads to handle the case where the app was terminated.
  static Future<void> checkInitialMessage() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _handleTap(msg);
  }

  static void _handleTap(RemoteMessage message) {
    final action   = message.data['action']    as String?;
    final actionId = message.data['action_id'] as String?;
    final id       = actionId != null ? int.tryParse(actionId) : null;

    switch (action) {
      case 'service_detail':
        _container?.read(notificationHighlightServiceProvider.notifier).state = id;
        _container?.read(notificationExploreTabProvider.notifier).state = 1;
        _container?.read(notificationPendingRouteProvider.notifier).state = '/explore';
      case 'services':
        _container?.read(notificationExploreTabProvider.notifier).state = 1;
        _container?.read(notificationHighlightServiceProvider.notifier).state = null;
        _container?.read(notificationPendingRouteProvider.notifier).state = '/explore';
      case 'news':
        _container?.read(notificationExploreTabProvider.notifier).state = 0;
        _container?.read(notificationHighlightServiceProvider.notifier).state = null;
        _container?.read(notificationPendingRouteProvider.notifier).state = '/explore';
      case 'contracts':
        _container?.read(notificationPendingRouteProvider.notifier).state = '/contracts';
      case 'invoices':
        _container?.read(notificationPendingRouteProvider.notifier).state = '/invoices';
      case 'invoice_detail':
      case 'payment_confirmed':
        _container?.read(notificationPendingRouteProvider.notifier).state =
            id != null ? '/invoices/$id' : '/invoices';
      case 'community_profile':
      case 'contract_new':
      case 'milestone':
      case 'rank_up':
        _container?.read(notificationPendingRouteProvider.notifier).state =
            id != null ? '/community/clients/$id' : '/explore';
      case 'leaderboard':
        _container?.read(notificationExploreTabProvider.notifier).state = 3;
        _container?.read(notificationPendingRouteProvider.notifier).state = '/explore';
      default:
        break;
    }
  }

  static void _showLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _fln.show(
      n.hashCode, n.title, n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }

  static Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiClient().dio.put('/auth/fcm-token', data: {'fcm_token': token});
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try { await ApiClient().dio.put('/auth/fcm-token', data: {'fcm_token': t}); }
        catch (_) {}
      });
    } catch (_) {}
  }
}
