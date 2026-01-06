import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nebeng_app/models/report.dart';
import 'dart:convert';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import AuthProvider

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AuthProvider _authProvider; // Dependensi AuthProvider

  // New pagination states
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isFetchingMore = false; // To prevent multiple simultaneous fetches

  StudentProvider(this._authProvider); // Constructor menerima AuthProvider
  Student? _selectedStudent; // Untuk detail siswa yang dipilih
  Student? get selectedStudent => _selectedStudent;
  List<Report> _studentReports = [];
  List<Report> get studentReports => _studentReports;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isFetchingMore => _isFetchingMore;

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchStudents({int? classId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    String url = '${AppConstants.apiUrl}/students';
    if (classId != null) {
      url = '${AppConstants.apiUrl}/students/class/$classId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // print(response.body);
        List<dynamic> data = json.decode(response.body);
        _students = data.map((json) => Student.fromJson(json)).toList();
      } else {
        _errorMessage = 'Gagal memuat data siswa: ${response.statusCode}';
        debugPrint('Failed to load students: ${response.body}');
      }
    }on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      debugPrint('Error fetching students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // filter

  Future<void> fetchStudentsall({bool refresh = false, int? classId}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _students.clear(); // Clear existing students only on refresh
    }
    if (!_hasMoreData && !refresh)
      return; // Don't fetch if no more data and not refreshing
    if (_isLoading) return; // Prevent multiple simultaneous full fetches

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    String? _urlsearch;
    if (classId != null) {
      _urlsearch = "class_id=${classId}";
    }

    final url = Uri.parse(
      '${AppConstants.apiUrl}/students/filter?$_urlsearch&page=$_currentPage&limit=20',
    ); // Tambahkan parameter pagination
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> data =
            responseData['data']; // Asumsi API mengembalikan {data: [...], meta: {pagination_info}}

        List<Student> newStudents =
            data.map((json) => Student.fromJson(json)).toList();
        _students.addAll(newStudents);

        // Update pagination state based on API response
        _hasMoreData =
            responseData['next_page_url'] !=
            null; // Cek dari meta data API Anda
        if (_hasMoreData) {
          _currentPage++;
        }
      } else {
        _errorMessage =
            'Gagal memuat data siswa: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
      }
    }on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch more students for infinite scrolling
  Future<void> fetchNextPageOfStudents() async {
    if (_isLoading || _isFetchingMore || !_hasMoreData)
      return; // Don't fetch if already busy, no more data

    _isFetchingMore = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse(
      '${AppConstants.apiUrl}/students/filter?page=$_currentPage&limit=20',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> data = responseData['data'];

        List<Student> newStudents =
            data.map((json) => Student.fromJson(json)).toList();
        _students.addAll(newStudents);

        _hasMoreData = responseData['next_page_url'] != null;
        if (_hasMoreData) {
          _currentPage++;
        }
      } else {
        // Handle error, maybe show a temporary snackbar
        debugPrint('Error fetching next page: ${response.body}');
      }
    }on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      debugPrint('Network error fetching next page: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // siswa kelasku

  Future<void> fetchStudents_siswaku({int? classId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    String url = '${AppConstants.apiUrl}/student/myclass';
    // if (classId != null) {
    //   url = '${AppConstants.apiUrl}/students/class/$classId';
    // }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // print(response.body);

        List<dynamic> data = json.decode(response.body);
        _students = data.map((json) => Student.fromJson(json)).toList();
      } else {
        _errorMessage = 'Gagal memuat data siswa: ${response.statusCode}';
        debugPrint('Failed to load students: ${response.body}');
      }
    }on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      debugPrint('Error fetching students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // detail siswa

  Future<void> fetchStudentDetail(int studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    String url = '${AppConstants.apiUrl}/student/$studentId/reports';
    // if (classId != null) {
    //   url = '${AppConstants.apiUrl}/students/class/$classId';
    // }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // print(response.body);

        final Map<String, dynamic> responseData = json.decode(response.body);
        _selectedStudent = Student.fromJson(responseData['student']);
        List<dynamic> reportsData = responseData['reports'];
        _studentReports =
            reportsData.map((json) => Report.fromJson(json)).toList();
        debugPrint(
          'Fetched student ${studentId} with ${_studentReports.length} reports successfully.',
        );
      } else {
        _errorMessage =
            'Gagal memuat data siswa di dalam detail: ${response.statusCode}';
        debugPrint('Failed to load students: ${response.body}');
      }
    }on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      debugPrint('Error fetching students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
