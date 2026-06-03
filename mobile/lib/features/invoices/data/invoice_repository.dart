import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'invoice_model.dart';

class InvoiceRepository {
  final ApiClient _api;
  InvoiceRepository(this._api);

  Future<List<InvoiceModel>> getInvoices() async {
    final res = await _api.dio.get('/invoices');
    return (res.data as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  Future<String> initiatePayment(int invoiceId) async {
    final res = await _api.dio.post('/payments/initiate', data: {'invoice_id': invoiceId});
    return res.data['payment_url'] as String;
  }
}

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository(ApiClient()));

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  return ref.read(invoiceRepositoryProvider).getInvoices();
});
