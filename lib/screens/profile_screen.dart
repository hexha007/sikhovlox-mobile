// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilku'),
          backgroundColor: AppColors.primaryBlue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Data pengguna tidak ditemukan.',
                style: AppStyles.bodyText1.copyWith(color: AppColors.darkGrey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Login Ulang',
                  style: AppStyles.buttonTextStyle.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background dengan gradasi atau gambar
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Informasi Profil di Tengah
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.white,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentUser.name ?? 'Nama Pengguna',
                          style: AppStyles.heading2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          currentUser.role?.toTitleCase() ??
                              'Peran Tidak Diketahui',
                          style: AppStyles.bodyText1.copyWith(
                            color: AppColors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tombol logout di AppBar
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.white),
                tooltip: 'Logout',
                onPressed: () async {
                  await authProvider.logout();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Card untuk Informasi Kontak
                    _buildInfoCard(
                      context,
                      title: 'Informasi Kontak',
                      icon: Icons.contact_mail,
                      children: [
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          currentUser.email ?? 'Tidak Tersedia',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Card untuk Informasi Peran/Organisasi
                    _buildInfoCard(
                      context,
                      title: 'Informasi Peran',
                      icon: Icons.info_outline,
                      children: [
                        _buildInfoRow(
                          Icons.work,
                          'Peran',
                          currentUser.role?.toTitleCase() ?? 'Tidak Tersedia',
                        ),
                        if (currentUser.classId != null &&
                            currentUser.role == 'wali_kelas')
                          _buildInfoRow(
                            Icons.school,
                            'Kelas',
                            'Kelas ${currentUser.studentClass}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Card untuk Statistik (contoh placeholder)
                    _buildInfoCard(
                      context,
                      title: 'Statistik Saya',
                      icon: Icons.bar_chart,
                      children: [
                        _buildStatRow(
                          Icons.file_copy,
                          'Laporan Dibuat',
                          '',
                        ), // Data placeholder
                        _buildStatRow(
                          Icons.task_alt,
                          'Laporan Diselesaikan',
                          '',
                        ), // Data placeholder
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk membuat Card informasi
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 8, // Sedikit lebih tinggi untuk efek modern
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppStyles.heading3.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1, color: AppColors.lightGrey),
            ...children, // Memecah list widget ke dalam column
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk baris informasi di dalam Card
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.darkGrey),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyText1.copyWith(color: AppColors.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk baris statistik di dalam Card
  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.warningOrange),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlue,
            ),
          ),
          const Spacer(), // Dorong nilai ke kanan
          Text(
            value,
            style: AppStyles.heading3.copyWith(color: AppColors.warningOrange),
          ),
        ],
      ),
    );
  }
}

// Extensi String untuk mengubah ke Title Case (jika belum ada)
// Pastikan ini ada di file utils/app_styles.dart atau di tempat lain yang bisa diakses
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');
}
