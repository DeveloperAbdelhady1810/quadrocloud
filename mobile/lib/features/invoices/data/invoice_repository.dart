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

  Future<InvoiceModel> getInvoice(int id) async {
    final res = await _api.dio.get('/invoices/$id');
    return InvoiceModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> initiatePayment(int invoiceId) async {
    final res = await _api.dio.post('/payments/initiate', data: {'invoice_id': invoiceId});
    return res.data['payment_url'] as String;
  }

  Future<void> sendEmail(int invoiceId) async {
    await _api.dio.post('/invoices/$invoiceId/send-email');
  }
}

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository(ApiClient()));

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  return ref.read(invoiceRepositoryProvider).getInvoices();
});

final invoiceDetailProvider = FutureProvider.family<InvoiceModel, int>((ref, id) async {
  return ref.read(invoiceRepositoryProvider).getInvoice(id);
});
