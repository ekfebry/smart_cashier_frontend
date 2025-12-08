import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  bool _isAuthenticated = false;
  User? _user;

  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;

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

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    final apiService = ApiService();
    await apiService.logout();
    _token = null;
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
