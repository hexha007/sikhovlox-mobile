import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nebeng_app/models/user.dart';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  List<User> _bkUsers = [];
  bool _isLoadingBkUsers = false;
  String? _bkUsersErrorMessage;
  final AuthProvider _authProvider;

  UserProvider(this._authProvider);
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<User> get bkUsers => _bkUsers;
  bool get isLoadingBkUsers => _isLoadingBkUsers;
  String? get bkUsersErrorMessage => _bkUsersErrorMessage;

  Future<void> fetchBkUsers(int? classid) async {
    _isLoadingBkUsers = true;
    _bkUsersErrorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse(
      '${AppConstants.apiUrl}/user/filter?class_id=${classid}',
    ); // Filter by role=bk
    // debugPrint('ini adalah link nya${url}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      // debugPrint(
      //   'ini adalah link nya${response.body} dan ini adalah kelas nya ${classid}',
      // );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _bkUsers = data.map((json) => User.fromJson(json)).toList();
        // debugPrint('Fetched ${response.body} BK users.');
      } else {
        _bkUsersErrorMessage =
            'Gagal memuat petugas BK: ${response.statusCode}';
        debugPrint(
          'Failed to load BK users: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _bkUsersErrorMessage = 'Terjadi kesalahan jaringan';
      debugPrint('Error fetching BK users');
    } finally {
      _isLoadingBkUsers = false;
      notifyListeners();
    }
  }
}
