import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:nebeng_app/providers/connectivity_service.dart';

class _ConnectivitySnackBarWrapper extends StatefulWidget {
  final Widget child;
  final ConnectivityService connectivityService;

  const _ConnectivitySnackBarWrapper({
    required this.child,
    required this.connectivityService,
  });

  @override
  _ConnectivitySnackBarWrapperState createState() => _ConnectivitySnackBarWrapperState();
}

class _ConnectivitySnackBarWrapperState extends State<_ConnectivitySnackBarWrapper> {
  // Variabel untuk menyimpan ScaffoldMessengerState
  // Ini penting agar SnackBar bisa ditampilkan dari mana saja
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    // Dapatkan ScaffoldMessengerState setelah widget dibangun sepenuhnya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldMessengerState = ScaffoldMessenger.of(context);
    });

    // Daftarkan listener ke ValueNotifier connectionStatus di ConnectivityService
    widget.connectivityService.connectionStatus.addListener(_onConnectionStatusChanged);
    // Panggil sekali saat inisialisasi untuk menampilkan status awal
    _onConnectionStatusChanged();
  }

  @override
  void dispose() {
    // Hapus listener untuk menghindari memory leaks
    widget.connectivityService.connectionStatus.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }

  // Fungsi yang dipanggil setiap kali status koneksi berubah
  void _onConnectionStatusChanged() {
    final ConnectivityResult status = widget.connectivityService.connectionStatus.value;
    
    // Pastikan _scaffoldMessengerState sudah tersedia
    if (_scaffoldMessengerState == null || !_scaffoldMessengerState!.mounted) {
      debugPrint("ScaffoldMessengerState not ready or unmounted.");
      return;
    }

    // Sembunyikan SnackBar yang sedang aktif untuk menghindari penumpukan
    _scaffoldMessengerState!.hideCurrentSnackBar();

    if (status == ConnectivityResult.none) {
      // Jika tidak ada koneksi, tampilkan SnackBar peringatan offline
      _scaffoldMessengerState!.showSnackBar(
        SnackBar(
          content: const Text(
            'Anda sedang offline. Silakan periksa koneksi internet Anda.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(days: 365), // Durasi sangat panjang agar tetap terlihat
          behavior: SnackBarBehavior.floating, // Agar tidak menutupi bottom navigation bar
          margin: const EdgeInsets.all(10), // Memberikan sedikit margin dari tepi
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'TUTUP',
            textColor: Colors.white,
            onPressed: () {
              _scaffoldMessengerState!.hideCurrentSnackBar(); // Izinkan pengguna menutup manual
            },
          ),
        ),
      );
    } else {
      // Jika koneksi kembali normal, tampilkan SnackBar konfirmasi
      _scaffoldMessengerState!.showSnackBar(
        SnackBar(
          content: const Text(
            'Koneksi internet kembali normal.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3), // Durasi singkat untuk notifikasi
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child; // Render aplikasi utama Anda
  }
}