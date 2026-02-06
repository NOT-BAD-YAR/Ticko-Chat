import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  // Use localhost for Web, 10.0.2.2 for Android Emulator
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/auth';
    }
    return 'http://10.0.2.2:5000/api/auth';
  }

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get token => _token;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userData = prefs.getString('user');

    if (token != null && userData != null) {
      _token = token;
      _user = json.decode(userData);
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));
        
        notifyListeners();
      } else {
        throw data['message'] ?? 'Login failed';
      }
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, {String? profilePic}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'fullName': name, 
        'email': email, 
        'password': password,
      };
      
      if (profilePic != null) {
        body['profilePic'] = profilePic;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _token = data['token'];
        _user = data;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));
        
        notifyListeners();
      } else {
        throw data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String email, String? password, {String? profilePic}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'fullName': name,
        'email': email,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      if (profilePic != null) {
        body['profilePic'] = profilePic;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _user = data;
        if (data['token'] != null) {
          _token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        
        notifyListeners();
      } else {
        throw data['message'] ?? 'Update failed';
      }
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgotpassword'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({'email': email}),
      );
      
      if (response.statusCode != 200) {
         final data = json.decode(response.body);
         throw Exception(data['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
     _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/resetpassword'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      );
      
      if (response.statusCode != 200) {
         final data = json.decode(response.body);
         throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
