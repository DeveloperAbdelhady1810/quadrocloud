import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/api_client.dart';
import 'invoice_model.dart';
import 'package:dio/dio.dart';

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

  Future<({String paymentUrl, String paymobOrderId})> initiatePayment(int invoiceId) async {
    final res = await _api.dio.post('/payments/initiate', data: {'invoice_id': invoiceId});
    return (
      paymentUrl: res.data['payment_url'] as String,
      paymobOrderId: (res.data['paymob_order_id'] ?? '') as String,
    );
  }

  Future<bool> verifyPayment({required String paymobOrderId, String? transactionId}) async {
    final res = await _api.dio.post('/payments/verify', data: {
      'paymob_order_id': paymobOrderId,
      if (transactionId != null) 'transaction_id': transactionId,
    });
    return res.data['paid'] == true;
  }

  Future<void> sendEmail(int invoiceId) async {
    await _api.dio.post('/invoices/$invoiceId/send-email');
  }

  Future<void> downloadPdf(int invoiceId, String invoiceNumber) async {
    final res = await _api.dio.get(
      '/invoices/$invoiceId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice-$invoiceNumber.pdf');
    await file.writeAsBytes(res.data as List<int>);
    await OpenFilex.open(file.path);
  }
}

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository(ApiClient()));

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  return ref.read(invoiceRepositoryProvider).getInvoices();
});

final invoiceDetailProvider = FutureProvider.family<InvoiceModel, int>((ref, id) async {
  return ref.read(invoiceRepositoryProvider).getInvoice(id);
});
