import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'payment_model.dart';

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  Future<List<PaymentModel>> getPayments() async {
    final res = await _api.dio.get('/payments');
    return (res.data as List).map((e) => PaymentModel.fromJson(e)).toList();
  }
}

final paymentRepositoryProvider = Provider((ref) => PaymentRepository(ApiClient()));

final paymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  return ref.read(paymentRepositoryProvider).getPayments();
});
