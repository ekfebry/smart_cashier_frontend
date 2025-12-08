import 'package:flutter/material.dart';
import '../models/product.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class OrderProvider with ChangeNotifier {
  final List<OrderItem> _selectedItems = [];

  List<OrderItem> get selectedItems => _selectedItems;

  int get totalItems => _selectedItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _selectedItems.fold(0, (sum, item) => sum + item.total);

  bool get hasItems => _selectedItems.isNotEmpty;

  void addItem(Product product) {
    final existingIndex = _selectedItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _selectedItems[existingIndex].quantity++;
    } else {
      _selectedItems.add(OrderItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(Product product) {
    _selectedItems.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void incrementQuantity(Product product) {
    final index = _selectedItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _selectedItems[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(Product product) {
    final index = _selectedItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_selectedItems[index].quantity > 1) {
        _selectedItems[index].quantity--;
        notifyListeners();
      } else {
        _selectedItems.removeAt(index);
        notifyListeners();
      }
    }
  }

  void updateQuantity(Product product, int quantity) {
    final index = _selectedItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (quantity <= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  int getQuantity(Product product) {
    final item = _selectedItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => OrderItem(product: product, quantity: 0),
    );
    return item.quantity;
  }

  bool isSelected(Product product) {
    return _selectedItems.any((item) => item.product.id == product.id);
  }

  void clear() {
    _selectedItems.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getOrderItems() {
    return _selectedItems.map((item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
      'unit_price': item.product.price,
      'subtotal': item.total,
    }).toList();
  }
}
