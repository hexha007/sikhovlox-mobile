// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Memanggil method baru untuk mengambil JUMLAH tugas
        Provider.of<ReportProvider>(
          context,
          listen: false,
        ).fetchAssignedReportsCount();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        // --- BARU: RefreshIndicator ---
        onRefresh: () async {
          // Panggil method refreshReports dari provider
          await Provider.of<ReportProvider>(
            context,
            listen: false,
          ).refreshReports();
        },
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Penting untuk bisa scroll dan refresh
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, ${currentUser?.name ?? 'Pengguna'}!',
                  style: AppStyles.heading1.copyWith(color: AppColors.darkBlue),
                ),
                Row(
                  spacing: 10,
                  children: [
                    Text(
                      'Peran: ${currentUser?.role?.toTitleCase() ?? 'Tidak Diketahui'}',
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),

                    Text(
                      ' ${currentUser?.class_name?.toTitleCase() ?? 'Tidak Diketahui'}',
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                GridView.count(
                  crossAxisCount: 2, // 2 kolom
                  shrinkWrap:
                      true, // Agar GridView menyesuaikan tingginya dengan konten
                  physics:
                      const NeverScrollableScrollPhysics(), // Nonaktifkan scrolling internal GridView
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: [
                    _buildMenuItem(
                      context: context,
                      title: 'Laporanku',
                      icon: Icons.assignment,
                      color: AppColors.primaryBlue,
                      onTap: () => Navigator.pushNamed(context, '/my-reports'),
                    ),

                    if (currentUser?.role == 'wali_kelas' ||
                        currentUser?.role == 'bk')
                      // --- BAGIAN INI UNTUK MENAMPILKAN JUMLAH TUGAS ---
                      Consumer<ReportProvider>(
                        // Menggunakan Consumer untuk mendengarkan ReportProvider
                        builder: (context, reportProvider, child) {
                          // Mendapatkan jumlah tugas yang ditugaskan dari provider
                          final assignedCount =
                              reportProvider.assignedReportsCount;

                          // Teks subtitle yang akan ditampilkan
                          String subtitleText;
                          if (reportProvider.isLoading) {
                            subtitleText = 'Memuat...';
                          } else if (assignedCount > 0) {
                            subtitleText = '$assignedCount Tugas Baru';
                          } else {
                            subtitleText = 'tidak ada tugas';
                          }
                          return _buildMenuItem(
                            context: context,
                            title: 'Tugasku',
                            subtitle: subtitleText,
                            icon: Icons.task_alt,
                            color: AppColors.successGreen,
                            onTap:
                                () => Navigator.pushNamed(context, '/my-tasks'),
                          );
                        },
                      ),
                    if (currentUser?.role == 'wali_kelas' ||
                        currentUser?.role == 'bk')
                      _buildMenuItem(
                        context: context,
                        title: 'Siswaku',
                        icon: Icons.people,
                        color: AppColors.warningOrange,
                        onTap:
                            () => Navigator.pushNamed(context, '/my-students'),
                      ),
                    _buildMenuItem(
                      context: context,
                      title: 'Profilku',
                      icon: Icons.person,
                      color: AppColors.errorRed,
                      onTap: () => Navigator.pushNamed(context, '/my-profile'),
                    ),
                    _buildMenuItem(
                      context: context,
                      title: 'Buat Laporan',
                      icon: Icons.add_box,
                      color:
                          AppColors
                              .warningOrange, // Tambahkan warna baru di AppColors
                      onTap: () => Navigator.pushNamed(context, '/add-report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-report'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

Widget _buildMenuItem({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color color,
  String? subtitle, // Tambahkan parameter subtitle
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppStyles.heading3.copyWith(color: AppColors.darkBlue),
            textAlign: TextAlign.center,
          ),

          if (subtitle != null) // Tampilkan subtitle jika ada
            Padding(
              padding: const EdgeInsets.only(top: 4.0), // Beri sedikit jarak
              child: Text(
                subtitle,
                style: AppStyles.bodyText2.copyWith(
                  color: AppColors.warningOrange, // Warna yang menonjol
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    ),
  );
}

// Extensi String untuk mengubah ke Title Case (jika belum ada)
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');
}
