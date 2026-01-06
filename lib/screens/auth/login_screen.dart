import 'package:flutter/material.dart';
import 'package:nebeng_app/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/widgets/custom_button.dart';
import 'package:nebeng_app/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // await Provider.of<AuthProvider>(
        //   context,
        //   listen: false,
        // ).login(_emailController.text, _passwordController.text);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(
          _emailController.text,
          _passwordController.text,
        );

        if (authProvider.token != null) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ??
                      'Login failed. Please try again.',
                ),
                backgroundColor: Colors.red, // Indicate error
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo atau Ilustrasi
                // Hero(
                //   tag: 'app_logo', // Untuk animasi hero dari splash screen
                //   child: Icon(
                //     Icons.school, // Ganti dengan ikon atau aset logo Anda
                //     size: 120,
                //     color: AppColors.primaryBlue,
                //   ),
                // ),
                Image.asset(
                  'assets/icon/logo.png', // <--- Ganti 'your_logo.png' dengan nama file gambar Anda
                  height: 120, // Sesuaikan tinggi logo sesuai kebutuhan
                  width: 120, // Sesuaikan lebar logo sesuai kebutuhan
                  // fit: BoxFit.contain, // Opsional: Sesuaikan bagaimana gambar mengisi ruang
                ),
                const SizedBox(height: 32),
                Text(
                  'Selamat Datang Kembali!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Silakan masuk untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Masukkan email Anda',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CustomTextField(
                //   controller: _passwordController,
                //   labelText: 'Password',
                //   hintText: 'Masukkan password Anda',
                //   obscureText: true,
                //   prefixIcon: Icons.lock,
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Password tidak boleh kosong';
                //     }
                //     if (value.length < 6) {
                //       return 'Password minimal 6 karakter';
                //     }
                //     return null;
                //   },
                // ),
                TextFormField(
                  controller: _passwordController,
                  // Mengatur apakah teks disembunyikan atau tidak
                  obscureText: _obscureText,
                  decoration: AppStyles.standardInputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icons.lock,
                    // Menambahkan IconButton sebagai suffixIcon
                    suffixIcon: IconButton(
                      // Mengganti ikon berdasarkan state _obscureText
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.darkGrey, // Sesuaikan warna ikon
                      ),
                      // Mengubah state _obscureText saat tombol ditekan
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password cannot be empty.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: _isLoading ? 'Loading...' : 'Masuk',
                  onPressed: _isLoading ? null : _login,
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 20),
                // TextButton(
                //   onPressed: () {
                //     // Navigator.of(context).pushNamed('/register');
                //     // Implementasi navigasi ke halaman register
                //   },
                //   child: Text(
                //     'Belum punya akun? Daftar Sekarang',
                //     style: TextStyle(
                //       color: AppColors.secondaryBlue,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
