class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imagePath;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imagePath,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'],
      imagePath: json['image_path'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_path': imagePath,
      'quantity': quantity,
    };
  }
}