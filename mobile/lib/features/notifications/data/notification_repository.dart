import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient _api;
  NotificationRepository(this._api);

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _api.dio.get('/notifications');
    return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }
}

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(ApiClient()));

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.read(notificationRepositoryProvider).getNotifications();
});
