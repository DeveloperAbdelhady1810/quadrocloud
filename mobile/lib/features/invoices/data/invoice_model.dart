class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final double amount;
  final String status;
  final String? dueDate;
  final String? paidAt;
  final String? paymentMethod;
  final String? description;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.description,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> j) => InvoiceModel(
        id: j['id'],
        invoiceNumber: j['invoice_number'],
        amount: (j['amount'] as num).toDouble(),
        status: j['status'],
        dueDate: j['due_date'],
        paidAt: j['paid_at'],
        paymentMethod: j['payment_method'],
        description: j['description'],
      );

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
  bool get isUnpaid => status == 'unpaid';
}
