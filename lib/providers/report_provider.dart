import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportProvider with ChangeNotifier {
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AuthProvider _authProvider;

  ReportProvider(this._authProvider);

  List<Report> get reports => _reports;
  Report? _currentReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int _assignedReportsCount = 0;

  Report? get currentReport => _currentReport;

  // BARU: Getter untuk jumlah laporan yang ditugaskan
  int get assignedReportsCount => _assignedReportsCount;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Deklarasi variabel baru di sini ---
  int _assignedReportsTodayCount = 0; // Inisialisasi dengan 0
  int _forwardedReportsCount = 0; // Inisialisasi dengan 0
  List<Report> _assignedReportsList = [];

  // Getter baru untuk statistik
  int get assignedReportsTodayCount => _assignedReportsTodayCount;
  int get forwardedReportsCount => _forwardedReportsCount;
  List<Report> get assignedReportsList => _assignedReportsList;

  // Variabel BARU untuk My Reports
  List<Report> _myReportsList = [];
  String? _currentMyReportsFilterStatus; // Misal: 'baru', 'selesai', 'all'
  String? _currentMyReportsFilterType; // Misal: 'perilaku', 'akademik', 'all'
  String? _currentMyReportsFilterUrgency; // Misal: 'rendah', 'sedang', 'all'
  String? _currentMyReportsSearchQuery; // Kata kunci pencarian
  // Getter BARU untuk My Reports
  List<Report> get myReportsList => _myReportsList;
  String? get currentMyReportsFilterStatus => _currentMyReportsFilterStatus;
  String? get currentMyReportsFilterType => _currentMyReportsFilterType;
  String? get currentMyReportsFilterUrgency => _currentMyReportsFilterUrgency;
  String? get currentMyReportsSearchQuery => _currentMyReportsSearchQuery;

  // --- Fetch Reports ---
  Future<void> fetchReports({int? classId, String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint(
      'Attempting to fetch from URL: ${Uri.parse('${AppConstants.apiUrl}/reports')}',
    );

    try {
      String url = '${AppConstants.apiUrl}/reports';
      Map<String, String> queryParams = {};
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('API Response Body: ${tokenData}');
      // print(response.body);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        _reports = data.map((json) => Report.fromJson(json)).toList();
      } else {
        _errorMessage = "gagalm memuat data";
        // _errorMessage =
        //     'Gagal memuat data laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
        // debugPrint('Failed to load reports: ${response.body}');
      }
      notifyListeners();
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan';
      debugPrint('Error fetching reports: $_errorMessage');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get Single Report (for detail screen refresh) ---
  Future<Report?> getReportById(int reportId) async {
    final url = Uri.parse('${AppConstants.apiUrl}/reports/$reportId');
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      // debugPrint('Error getting report by ID: ${response.body}');

      if (response.statusCode == 200) {
        return Report.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to load report: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } catch (e) {
      debugPrint('Error getting report by ID: $e');
      // rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Add Report ---
  Future<void> addReport(Report newReport) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    // debugPrint('add ${newReport.toJson()}');
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/reports');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
        body: json.encode(newReport.toJson()),
      );

      if (response.statusCode == 201) {
        final addedReport = Report.fromJson(json.decode(response.body));
        _reports.add(addedReport);
        notifyListeners();
      } else {
        throw Exception(
          'Gagal menambah laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menambah laporan';
      // debugPrint('Error adding report: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Report ---
  Future<void> updateReport(int id, Report updatedReport) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/reports/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedReport.toJson()),
      );
      debugPrint('Error updating report tester: ${response.body}');

      if (response.statusCode == 200) {
        final index = _reports.indexWhere((report) => report.id == id);
        if (index != -1) {
          _reports[index] = Report.fromJson(json.decode(response.body));
        }
        notifyListeners();
      } else {
        throw Exception(
          'Gagal memperbarui laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui laporan: $e';
      debugPrint('Error updating report: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReporttutup(int id, String conclusion) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/reports/$id/close');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'conclusion': conclusion,
          'status': 'selesai', // jika status ditutup juga ingin diubah
        }),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final index = _reports.indexWhere((report) => report.id == id);
        if (index != -1) {
          _reports[index] = Report.fromJson(json.decode(response.body));
        }
        notifyListeners();
      } else {
        throw Exception(
          'Gagal memperbarui laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui laporan: $e';
      debugPrint('Error updating report: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Delete Report ---
  Future<void> deleteReport(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/reports/$id');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${tokenData}'},
      );

      if (response.statusCode == 204) {
        // No content on successful delete
        _reports.removeWhere((report) => report.id == id);
        notifyListeners();
      } else if (response.statusCode == 200) {
        // Some APIs return 200 with a message on success
        _reports.removeWhere((report) => report.id == id);
        notifyListeners();
      } else {
        throw Exception(
          'Gagal menghapus laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menghapus laporan: $e';
      debugPrint('Error deleting report: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardSummary() async {
    setLoading(true);
    setErrorMessage(null);
    try {
      String url = '${AppConstants.apiUrl}/dashboard-summary';
      final uri = Uri.parse(url);
      debugPrint('Fetching dashboard summary from URL: $uri');
      debugPrint('Auth Token: ${_authProvider.token}');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Dashboard Summary Status Code: ${response.statusCode}');
      debugPrint('Dashboard Summary Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _assignedReportsTodayCount =
            responseData['assigned_reports_today'] ?? 0;
        _forwardedReportsCount = responseData['forwarded_reports'] ?? 0;
        debugPrint('Dashboard summary loaded successfully.');
      } else {
        String message = 'Unknown Error';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (_) {
          message =
              response.body.isNotEmpty ? response.body : 'No message provided.';
        }
        setErrorMessage(
          'Gagal memuat ringkasan dashboard: ${response.statusCode} - $message',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan';
      // debugPrint('Error fetching reports: $_errorMessage');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Report?> fetchMyTasksSummary() async {
    String uri = '${AppConstants.apiUrl}/tugasku'; // Ganti endpoint
    final url = Uri.parse(uri);
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );

      // debugPrint('My Tasks Summary Status Code: ${response.statusCode}');
      // debugPrint('My Tasks Summary Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _assignedReportsTodayCount =
            responseData['assigned_reports_today'] ?? 0;
        _forwardedReportsCount = responseData['forwarded_reports'] ?? 0;

        List<dynamic> assignedReportsData =
            responseData['assigned_reports_list'] ?? [];
        _assignedReportsList =
            assignedReportsData.map((json) => Report.fromJson(json)).toList();

        debugPrint('My tasks summary loaded successfully.');
        debugPrint(
          'Assigned Reports List Count: ${_assignedReportsList.length}',
        ); // <-- TAMBAHKAN INI
        notifyListeners();
      } else {
        throw Exception(
          'Failed to load report: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan';
      // debugPrint('Error fetching reports: $_errorMessage');
      notifyListeners();
      // debugPrint('Error getting report by ID: $e');
      // rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyReports({
    String? status,
    String? reportType,
    String? urgencyLevel,
    String? searchQuery,
  }) async {
    _myReportsList = []; // Reset list sebelum fetch

    // Update filter state
    _currentMyReportsFilterStatus = status;
    _currentMyReportsFilterType = reportType;
    _currentMyReportsFilterUrgency = urgencyLevel;
    _currentMyReportsSearchQuery = searchQuery;
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String> queryParams = {};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (reportType != null && reportType != 'all')
        queryParams['report_type'] = reportType;
      if (urgencyLevel != null && urgencyLevel != 'all')
        queryParams['urgency_level'] = urgencyLevel;
      if (searchQuery != null && searchQuery.isNotEmpty)
        queryParams['search'] = searchQuery;

      Uri uri = Uri.parse(
        '${AppConstants.apiUrl}/my-reports',
      ).replace(queryParameters: queryParams); // Tambahkan parameter query

      // String url = '${AppConstants.apiUrl}/my-report';
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      // debugPrint('API Response Body: ${tokenData}');
      // print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> reportsData = responseData['reports'] ?? [];
        _myReportsList =
            reportsData.map((json) => Report.fromJson(json)).toList();
        debugPrint('Fetched ${_myReportsList.length} my reports successfully.');
      } else {
        _errorMessage =
            'Gagal memuat data laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
        debugPrint('Failed to load reports: ${response.body}');
      }
      notifyListeners();
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan';
      // debugPrint('Error fetching reports: $_errorMessage');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forwardReportToBk(int reportId) async {
    setLoading(true);
    setErrorMessage(null);
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    try {
      final uri = Uri.parse(
        '${AppConstants.apiUrl}/report/$reportId/forward-to-bk',
      );
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $tokenData',
          'Content-Type':
              'application/json', // Ini biasanya POST tanpa body, tapi pastikan header
        },
      );

      debugPrint('Forward to BK Status Code: ${reportId}');
      debugPrint('Forward to BK Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _currentReport = Report.fromJson(responseData['report']);
        setLoading(false);
        notifyListeners();
        return true;
      } else {
        String message = 'Unknown Error';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (_) {
          message =
              response.body.isNotEmpty
                  ? response.body
                  : 'Failed to forward report: No message provided.';
        }
        setErrorMessage('Gagal meneruskan laporan: ');
        setLoading(false);
        return false;
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
      setLoading(false);
      return false;
    } catch (e) {
      setErrorMessage('Terjadi kesalahan jaringan saat meneruskan laporan');
      // debugPrint('Error forwarding report to BK: $_errorMessage');
      setLoading(false);
      return false;
    }
  }

  Future<void> fetchAssignedReportsCount() async {
    setLoading(true);
    setErrorMessage(null);

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    // if (token == null || currentUser == null || currentUser.id == null) {
    //   setErrorMessage(
    //     'Token otentikasi atau informasi pengguna tidak ditemukan. Harap login kembali.',
    //   );
    //   setLoading(false);
    //   return;
    // }

    try {
      // Memanggil API baru untuk menghitung
      final uri = Uri.parse('${AppConstants.apiUrl}/report/assigned/count');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $tokenData',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'Fetch Assigned Reports Count Status Code: ${response.statusCode}',
      );
      debugPrint('Fetch Assigned Reports Count Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _assignedReportsCount = responseData['count'] ?? 0; // Ambil jumlahnya
        debugPrint('ini adalah ${_assignedReportsCount}');
        print('ini hasilnya');
      } else {
        String message = 'Unknown Error';
        try {
          final errorBody = json.decode(response.body);
          message = errorBody['message'] ?? message;
        } catch (_) {
          message =
              response.body.isNotEmpty
                  ? response.body
                  : 'Failed to fetch assigned reports count: No message provided.';
        }
        setErrorMessage(
          'Gagal memuat jumlah laporan yang ditugaskan: ${response.statusCode} - $message',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan';
      // debugPrint('Error fetching reports: $_errorMessage');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReports() async {
    // Cukup panggil ulang fetchReports
    await fetchAssignedReportsCount();
  }
}
