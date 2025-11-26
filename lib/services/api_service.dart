import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
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

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      await removeToken();
    } else {
      throw Exception('Logout failed');
    }
  }

  // Products
  Future<List<Product>> getProducts({String? search, String? category}) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getRecommendations() async {
    final response = await http.get(Uri.parse('$baseUrl/recommendations'), headers: await getHeaders());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommendations');
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
      final List data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Order> createOrder(List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await getHeaders(),
      body: jsonEncode({'items': items}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data);
    } else {
      throw Exception('Failed to create order');
    }
  }
}