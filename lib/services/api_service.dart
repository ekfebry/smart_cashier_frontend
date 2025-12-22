import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/notification.dart';
import '../models/category.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseOrigin {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static String get baseUrl => '$baseOrigin/api';

  static String? resolveImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http')) return relativePath;
    final cleanedPath = relativePath.replaceFirst(RegExp('^/'), '');
    return '$baseOrigin/storage/$cleanedPath';
  }

  // Helper method to test backend connectivity
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse(baseOrigin));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Temporary mock for testing without backend
    if (email == 'test@test.com' && password == '123456') {
      debugPrint('Mock login successful for test credentials');
      final mockData = {'token': 'mock_token_123', 'user': {'id': 1, 'name': 'Test User', 'email': email}};
      await setToken(mockData['token'] as String);
      return mockData;
    }

    try {
      debugPrint('Attempting login to: $baseUrl/login with email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'email': email,
          'password': password,
        },
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          await setToken(data['token']);
          return data;
        } else {
          throw Exception('Login failed: Token not found in response');
        }
      } else {
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception('Login failed: $errorMessage');
        } catch (_) {
          throw Exception('Login failed: ${response.statusCode} - ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('ClientException: $e');
      throw Exception('Network error: Unable to connect to server. Check if backend is running at $baseUrl');
    } on FormatException catch (e) {
      debugPrint('FormatException: $e');
      throw Exception('Response format error: Invalid JSON response from server');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': role,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(Uri.parse('$baseUrl/user'), headers: await getHeaders());

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      if (response.statusCode == 401) {
        await removeToken();
      }
      throw Exception('Failed to load user profile');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 401) {
      await removeToken();
    } else {
      throw Exception('Logout failed: ${response.statusCode}');
    }
  }

  // Products
  Future<List<Product>> getProducts({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    List<String>? tags,
    String? sortBy,
    String? sortOrder,
    bool? inStock,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;
    if (inStock != null && inStock) queryParams['in_stock'] = 'true';

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle paginated response structure: {"data": [...], "meta": {...}, "links": {...}}
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getRecommendations() async {
    final response = await http.get(Uri.parse('$baseUrl/recommendations'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Product>> getPromotions() async {
    final response = await http.get(Uri.parse('$baseUrl/promos'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load promotions');
    }
  }

  Future<List<Product>> getTopSellers() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/top-sellers'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) {
        if (json is Map<String, dynamic> && json['product'] != null) {
          return Product.fromJson(Map<String, dynamic>.from(json['product']));
        }
        return Product.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } else {
      throw Exception('Failed to load top sellers');
    }
  }

  // Orders
  Future<List<Order>> getOrders({String? date, int? userId}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    if (userId != null) queryParams['user_id'] = userId.toString();

    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    String? orderType,
    String? tableNumber,
    String? notes,
    String? paymentMethod,
  }) async {
    final payload = {
      'items': items,
      if (orderType != null && orderType.isNotEmpty) 'order_type': orderType,
      if (tableNumber != null && tableNumber.isNotEmpty) 'table_number': tableNumber,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final orderData = jsonDecode(response.body);
      return Order.fromJson(orderData);
    } else {
      throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
    }
  }

  // Payments
  Future<List<Payment>> getPayments({int? orderId}) async {
    final queryParams = <String, String>{};
    if (orderId != null) queryParams['order_id'] = orderId.toString();

    final uri = Uri.parse('$baseUrl/payments').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payments');
    }
  }

  Future<Map<String, dynamic>> createPayment(int orderId, String method, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/payment'),
      headers: await getHeaders(),
      body: jsonEncode({
        'payment_method': method,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create payment: ${response.statusCode} - ${response.body}');
    }
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard'), headers: await getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  // Categories (if needed in future)
  Future<List<Category>> getAllCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Handle both paginated and direct array responses
      final List data = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
