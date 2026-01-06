// lib/services/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart'; // ValueNotifier memerlukan package ini

class ConnectivityService {
  // ValueNotifier untuk menyimpan dan memberitahukan status koneksi.
  // Diinisialisasi dengan ConnectivityResult.none sebagai nilai awal.
  final ValueNotifier<ConnectivityResult> connectionStatus =
      ValueNotifier<ConnectivityResult>(ConnectivityResult.none);

  ConnectivityService() {
    _initConnectivity(); // Panggil method inisialisasi saat objek ConnectivityService dibuat
  }

  // Method untuk inisialisasi dan mulai mendengarkan perubahan koneksi
  Future<void> _initConnectivity() async {
    // 1. Cek status koneksi saat ini (saat aplikasi dimulai)
    try {
      // checkConnectivity() sekarang mengembalikan List<ConnectivityResult>
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      // Ambil hasil pertama dari list. Jika list kosong, anggap sebagai none.
      connectionStatus.value =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
      connectionStatus.value =
          ConnectivityResult.none; // Default ke offline jika ada error
    }

    // 2. Mendengarkan perubahan status koneksi secara berkelanjutan
    // onConnectivityChanged juga mengembalikan Stream<List<ConnectivityResult>>
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Perbarui nilai ValueNotifier dengan status koneksi utama
      connectionStatus.value =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      debugPrint('Connectivity changed to: ${connectionStatus.value.name}');
    });
  }

  // Anda bisa menambahkan method lain di sini jika diperlukan,
  // misalnya untuk mengecek koneksi secara manual.
  Future<bool> isConnected() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }
}
