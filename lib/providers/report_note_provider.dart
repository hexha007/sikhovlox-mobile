import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nebeng_app/models/ReportNote.dart';
import 'dart:convert';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportNoteProvider with ChangeNotifier {
  List<ReportNote> _reportNotes = [];
  bool _isLoading = false;

  final AuthProvider _authProvider;

  ReportNoteProvider(this._authProvider);

  List<ReportNote> get reportNotes => _reportNotes;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Fetch Report Notes by Report ID ---
  Future<void> fetchReportNotes(int reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    // final url = Uri.parse('${AppConstants.apiUrl}/reports/$reportId/notes');
    final url = Uri.parse('${AppConstants.apiUrl}/report/$reportId/notes');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
      );
      // debugPrint('eksternal: ${reportId}');
      // debugPrint('Failed to load report notes: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _reportNotes = data.map((json) => ReportNote.fromJson(json)).toList();
      } else {
        _errorMessage =
            'Gagal memuat catatan laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
        // debugPrint('Failed to load report notes: ${response.body}');
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
      // debugPrint('Error fetching report notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Add Report Note ---
  // Future<void> addReportNote(int reportId, ReportNote newNote) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();

  //   final url = Uri.parse('${AppConstants.apiUrl}/reports/$reportId/notes');
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer ${_authProvider.token}',
  //         'Content-Type': 'application/json',
  //       },
  //       body: json.encode(
  //         newNote.toJson(),
  //       ), // Pastikan model toJson tidak include ID jika auto-increment
  //     );

  //     if (response.statusCode == 201) {
  //       final addedNote = ReportNote.fromJson(json.decode(response.body));
  //       _reportNotes.add(addedNote);
  //       notifyListeners();
  //     } else {
  //       throw Exception(
  //         'Gagal menambah catatan laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
  //       );
  //     }
  //   } catch (e) {
  //     _errorMessage = 'Terjadi kesalahan saat menambah catatan laporan: $e';
  //     debugPrint('Error adding report note: $e');
  //     rethrow;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // --- Add Report Note (Modified for file upload) ---
  Future<void> addReportNote(
    int reportId,
    ReportNote newNote,
    String trim, {
    File? photoFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse('${AppConstants.apiUrl}/reportsnotes');

    try {
      var request =
          http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer ${tokenData}'
            ..fields['note_type'] = newNote.noteType
            ..fields['note_detail'] = newNote.noteDetail;

      if (newNote.followUpPlan != null && newNote.followUpPlan!.isNotEmpty) {
        request.fields['follow_up_plan'] = newNote.followUpPlan!;
      }

      if (photoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final addedNote = ReportNote.fromJson(json.decode(response.body));
        // debugPrint('Failed to add report note: ${response.body}');

        _reportNotes.add(addedNote);
        notifyListeners();
      } else {
        _errorMessage =
            'Gagal menambah catatan laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}';
        debugPrint('Failed to add report note: ${response.body}');
        throw Exception(_errorMessage);
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menambah catatan laporan';
      debugPrint('Error adding report note');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Report Note ---
  Future<void> updateReportNote(
    int reportId,
    int noteId,
    ReportNote updatedNote,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse(
      '${AppConstants.apiUrl}/reports/$reportId/notes/$noteId',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${tokenData}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedNote.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _reportNotes.indexWhere((note) => note.id == noteId);
        if (index != -1) {
          _reportNotes[index] = ReportNote.fromJson(json.decode(response.body));
        }
        notifyListeners();
      } else {
        throw Exception(
          'Gagal memperbarui catatan laporan',
          // 'Gagal memperbarui catatan laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui catatan laporan:';
      debugPrint('Error updating report note: ');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Delete Report Note ---
  Future<void> deleteReportNote(int reportId, int noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    final url = Uri.parse(
      '${AppConstants.apiUrl}/reports/$reportId/notes/$noteId',
    );
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${tokenData}'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _reportNotes.removeWhere((note) => note.id == noteId);
        notifyListeners();
      } else {
        throw Exception(
          'Gagal menghapus catatan laporan',
          // 'Gagal menghapus catatan laporan: ${response.statusCode} - ${json.decode(response.body)['message'] ?? 'Unknown Error'}',
        );
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menghapus catatan laporan:';
      debugPrint('Error deleting report note:');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<ReportNote?> addReportNote2(
    int reportId,
    String noteType, // Parameter BARU
    String noteDetail, // GANTI: dari 'noteContent'
    String? followUpPlan, // Parameter BARU (nullable)
    File? photoFile, // GANTI: dari 'imageFile'
  ) async {
    setLoading(true);
    setErrorMessage(null);
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final tokenData = prefs.getString('token');

    // final url = Uri.parse('${AppConstants.apiUrl}/reports/$reportId/notes');
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}/reportsnotes'),
      );
      // print('ini link nya ${AppConstants.apiUrl}/reportsnotes');
      request.headers.addAll({
        'Authorization': 'Bearer ${tokenData}',
        // 'Content-Type': 'multipart/form-data', // Headers ini otomatis ditambahkan oleh MultipartRequest
      });

      request.fields['report_id'] = reportId.toString();
      request.fields['note_type'] = noteType; // Tambahkan note_type
      request.fields['note_detail'] = noteDetail; // Ganti note_detail
      if (followUpPlan != null && followUpPlan.isNotEmpty) {
        request.fields['follow_up_plan'] =
            followUpPlan; // Tambahkan follow_up_plan jika ada
      }

      if (photoFile != null) {
        // Ganti 'imageFile' menjadi 'photoFile'
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo', // Nama field harus sama dengan di Laravel ('photo')
            photoFile.path,
            filename: photoFile.path.split('/').last,
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Add Report Note Status Code: ${response.statusCode}');
      debugPrint('Add Report Note Body: $responseBody');

      if (response.statusCode == 201) {
        setErrorMessage('berhasil di simpan');
        debugPrint('sukses: $_errorMessage');

        final Map<String, dynamic> responseData = json.decode(responseBody);
        final newNote = ReportNote.fromJson(responseData);

        reportNotes.add(newNote); // Gunakan _currentReportNotes
        notifyListeners();
        return newNote;
      } else {
        String message = 'Unknown Error';
        try {
          final errorBody = json.decode(responseBody);
          message = errorBody['message'] ?? message;
        } catch (_) {
          message =
              responseBody.isNotEmpty
                  ? responseBody
                  : 'Failed to add note: No message provided.';
        }
        setErrorMessage(
          'Gagal menambahkan catatan',
          // 'Gagal menambahkan catatan: ${response.statusCode} - $message',
        );
        return null;
      }
    } on SocketException {
      // Tangani error koneksi internet
      _errorMessage =
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
      notifyListeners();
    } catch (e) {
      setErrorMessage('Terjadi kesalahan jaringan saat menambahkan catatan:');
      // debugPrint('Error adding report note: $_errorMessage');
      return null;
    } finally {
      setLoading(false);
    }
  }
}
