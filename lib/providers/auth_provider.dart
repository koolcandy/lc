import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'LEARNING_CENTER_TOKEN_KEY';
  String? _token;
  bool _isLoading = true;

  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _token = token;
    notifyListeners();
  }
}