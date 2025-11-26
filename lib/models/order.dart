import 'order_item.dart';
import 'user.dart';

class Order {
  final int id;
  final int userId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final User? user;
  final List<OrderItem>? orderItems;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.user,
    this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      orderItems: json['order_items'] != null
          ? (json['order_items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'user': user?.toJson(),
      'order_items': orderItems?.map((item) => item.toJson()).toList(),
    };
  }
}