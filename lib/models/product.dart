class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imagePath;
  final int stockQuantity;
  final int? minStockLevel;

  // Backward compatibility getter
  int get quantity => stockQuantity;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imagePath,
    required this.stockQuantity,
    this.minStockLevel,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      category: json['category'],
      imagePath: json['image_path'],
      stockQuantity: json['stock_quantity'] ?? 0,
      minStockLevel: json['min_stock_level'],
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
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
    };
  }
}
