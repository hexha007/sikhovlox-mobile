import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk menyimpan token
import 'package:nebeng_app/models/user.dart'; // Nanti akan dibuat
import 'package:nebeng_app/config/app_constants.dart'; // Nanti akan dibuat

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null;

  AuthProvider() {
    _loadUserAndToken();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _loadUserAndToken() async {
    _isLoading = true;
    // notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    if (userData != null && tokenData != null) {
      _user = User.fromJson(json.decode(userData));
      _token = tokenData;
      _isAuthenticated = true;
      // print('ini adalah ${_isAuthenticated}');
    }
    notifyListeners();
  }

  // Metode untuk menyimpan token dan data user ke Shared Preferences
  Future<void> _saveUserAndToken(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(user.toJson()));
  }

  // Metode untuk menghapus token dan data user dari Shared Preferences
  Future<void> _clearUserAndToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final url = Uri.parse('${AppConstants.apiUrl}/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(responseData['user']);
        _token = responseData['token'];
        _isAuthenticated = true;
        await _saveUserAndToken(_token!, _user!); // Simpan data

        _errorMessage = null;
        final prefs = await SharedPreferences.getInstance();
        // prefs.setString('userData', json.encode(responseData['user']));
        // prefs.setString('token', responseData['token']);
        notifyListeners();
      } else {
        // _errorMessage = json.decode(response.body)['message'] ?? 'Login failed';
        _user = null;
        _token = null;
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } on SocketException {
      // Tangani error koneksi internet
      _setErrorMessage(
        'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
      );
      _token = null;
      _user = null;
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan jaringan: $error';
      _user = null;
      _token = null;
      ;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    final url = Uri.parse('${AppConstants.apiUrl}/logout');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        _errorMessage = null;
      } else {
        _errorMessage =
            json.decode(response.body)['message'] ?? 'Logout failed';
      }
    } catch (e) {
      // Handle error, but still clear local data
      // debugPrint('Logout API error: $e');
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    } finally {
      _user = null;
      _token = null;
      await _clearUserAndToken(); // Hapus data dari Shared Preferences
      _isLoading = false;

      // _user = null;
      // _token = null;
      _isAuthenticated = false;
      // final prefs = await SharedPreferences.getInstance();
      // prefs.remove('userData');
      // prefs.remove('token');
      notifyListeners();
    }
  }

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  // Method baru untuk mengatur user saat ini
  void setCurrentUser(User? user) {
    _user = user;
    notifyListeners();
  }
}
