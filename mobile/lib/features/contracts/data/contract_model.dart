class ContractModel {
  final int id;
  final String name;
  final double price;
  final String billingCycle;
  final String? nextDueDate;
  final int daysUntilDue;
  final String? startDate;
  final String? endDate;
  final String status;

  const ContractModel({
    required this.id,
    required this.name,
    required this.price,
    required this.billingCycle,
    this.nextDueDate,
    required this.daysUntilDue,
    this.startDate,
    this.endDate,
    required this.status,
  });

  factory ContractModel.fromJson(Map<String, dynamic> j) => ContractModel(
        id: j['id'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        billingCycle: j['billing_cycle'],
        nextDueDate: j['next_due_date'],
        daysUntilDue: j['days_until_due'] ?? 0,
        startDate: j['start_date'],
        endDate: j['end_date'],
        status: j['status'],
      );
}
