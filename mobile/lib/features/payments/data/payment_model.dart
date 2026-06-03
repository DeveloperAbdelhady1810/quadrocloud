class PaymentModel {
  final int id;
  final String? invoiceNumber;
  final double amount;
  final String method;
  final String status;
  final String? paidAt;

  const PaymentModel({
    required this.id,
    this.invoiceNumber,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
        id: j['id'],
        invoiceNumber: j['invoice_number'],
        amount: (j['amount'] as num).toDouble(),
        method: j['method'],
        status: j['status'],
        paidAt: j['paid_at'],
      );
}
