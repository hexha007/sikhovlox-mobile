import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nebeng_app/models/student_class.dart';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentClassProvider with ChangeNotifier {
  List<StudentClass> _studentClasses = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AuthProvider _authProvider;

  StudentClassProvider(this._authProvider);

  List<StudentClass> get studentClasses => _studentClasses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStudentClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/student_classes');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      // print(response.body);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _studentClasses =
            data.map((json) => StudentClass.fromJson(json)).toList();
      } else {
        _errorMessage =
            'Gagal memuat data kelas: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
        debugPrint('Failed to load student classes: ${response.body}');
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      debugPrint('Error fetching student classes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambahkan metode CRUD lain untuk kelas jika diperlukan
}
