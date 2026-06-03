class ClientModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? companyName;
  final String? address;
  final String locale;

  const ClientModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.companyName,
    this.address,
    required this.locale,
  });

  factory ClientModel.fromJson(Map<String, dynamic> j) => ClientModel(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        phone: j['phone'],
        companyName: j['company_name'],
        address: j['address'],
        locale: j['locale'] ?? 'ar',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'company_name': companyName,
        'address': address,
        'locale': locale,
      };
}
