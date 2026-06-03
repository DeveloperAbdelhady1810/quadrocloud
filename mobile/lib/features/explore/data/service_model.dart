class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String? imagePath;
  final double? price;
  final bool showPrice;

  ServiceModel({required this.id, required this.name, this.description, this.icon, this.imagePath, this.price, required this.showPrice});

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    icon: j['icon'],
    imagePath: j['image_path'],
    price: j['price'] != null ? (j['price'] as num).toDouble() : null,
    showPrice: j['show_price'] ?? false,
  );
}
