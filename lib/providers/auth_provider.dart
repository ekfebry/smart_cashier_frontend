import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  bool _isAuthenticated = false;

  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuth() async {
    final apiService = ApiService();
    _token = await apiService.getToken();
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final apiService = ApiService();
    await apiService.logout();
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}