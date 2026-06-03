class ContractModel {
  final int id;
  final String name;
  final double price;
  final String billingCycle;
  final String? nextDueDate;
  final int daysUntilDue;
  final int gracePeriodDays;
  final String? startDate;
  final String? endDate;
  final String status;
  final int? unpaidInvoiceId;
  final double? payableAmount;

  const ContractModel({
    required this.id,
    required this.name,
    required this.price,
    required this.billingCycle,
    this.nextDueDate,
    required this.daysUntilDue,
    this.gracePeriodDays = 0,
    this.startDate,
    this.endDate,
    required this.status,
    this.unpaidInvoiceId,
    this.payableAmount,
  });

  bool get canPay => unpaidInvoiceId != null && payableAmount != null;

  factory ContractModel.fromJson(Map<String, dynamic> j) => ContractModel(
        id: j['id'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        billingCycle: j['billing_cycle'],
        nextDueDate: j['next_due_date'],
        daysUntilDue: j['days_until_due'] ?? 0,
        gracePeriodDays: j['grace_period_days'] ?? 0,
        startDate: j['start_date'],
        endDate: j['end_date'],
        status: j['status'],
        unpaidInvoiceId: j['unpaid_invoice_id'],
        payableAmount: j['payable_amount'] != null
            ? (j['payable_amount'] as num).toDouble()
            : null,
      );
}
