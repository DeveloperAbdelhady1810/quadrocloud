import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class DashboardData {
  final int overdueCount;
  final List<Map<String, dynamic>> pendingFees;
  final Map<String, dynamic>? nextInvoice;

  const DashboardData({
    required this.overdueCount,
    required this.pendingFees,
    this.nextInvoice,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        overdueCount: j['overdue_count'] ?? 0,
        pendingFees: List<Map<String, dynamic>>.from(j['pending_fees'] ?? []),
        nextInvoice: j['next_invoice'],
      );
}

class HomeRepository {
  final ApiClient _api;
  HomeRepository(this._api);

  Future<DashboardData> getDashboard() async {
    final res = await _api.dio.get('/dashboard');
    return DashboardData.fromJson(res.data);
  }
}

final homeRepositoryProvider = Provider((ref) => HomeRepository(ApiClient()));

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  return ref.read(homeRepositoryProvider).getDashboard();
});
