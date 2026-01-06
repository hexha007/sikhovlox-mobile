import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoggedIn = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Panggil fungsi untuk memeriksa status login
  }

  @override
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user');
    final user = prefs.getString('token');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.token;
    debugPrint('ini adalah ${currentUser}');

    // final authProvider = Provider.of<AuthProvider>(context);

    // Memberikan sedikit penundaan tambahan untuk efek splash screen
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Durasi tampil splash screen

    // setState(() {
    //   _isLoggedIn = token != null;
    //   _isLoading =
    //       false; // Setelah selesai memeriksa, set isLoading menjadi false
    // });

    // print(token != null);
    // Setelah status login diketahui dan penundaan selesai, lakukan navigasi
    if (token != null) {
      Navigator.of(context).pushReplacementNamed('/home');
      print('token berhasil ${user}');
    } else {
      // print('token gagal ${token}');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ganti dengan logo aplikasi Anda
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value * 1.2, // Animasi zoom-in
                    child: Image.asset(
                      'assets/images/logo.png', // <--- Ganti 'your_logo.png' dengan nama file gambar Anda
                      height: 120, // Sesuaikan tinggi logo sesuai kebutuhan
                      width: 120, // Sesuaikan lebar logo sesuai kebutuhan
                      // fit: BoxFit.contain, // Opsional: Sesuaikan bagaimana gambar mengisi ruang
                    ),
                    // child: Icon(
                    //   Icons.school, // Contoh ikon, ganti dengan logo Anda
                    //   size: 100,
                    //   color: AppColors.white,
                    // ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'SiBaguer',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: value * 2, // Animasi letter spacing
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
