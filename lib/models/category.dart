class Category {
  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imagePath: json['image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_path': imagePath,
    };
  }
}
