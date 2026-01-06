// lib/screens/assigned_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:nebeng_app/screens/reports/edit_report_screen.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

import 'package:intl/intl.dart'; // Untuk format tanggal

class AssignedReportsScreen extends StatefulWidget {
  const AssignedReportsScreen({super.key});

  @override
  State<AssignedReportsScreen> createState() => _AssignedReportsScreenState();
}

class _AssignedReportsScreenState extends State<AssignedReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyTasksData();
    });
  }

  Future<void> _loadMyTasksData() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    await reportProvider.fetchMyTasksSummary(); // Panggil method baru
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUser = authProvider.user;

        // Tampilkan layar ini hanya untuk BK atau Admin
        // if (currentUser?.role != 'BK' && currentUser?.role != 'admin') {
        //   return Scaffold(
        //     appBar: AppBar(title: const Text('Tugasku')),
        //     body: Center(
        //       child: Padding(
        //         padding: const EdgeInsets.all(24.0),
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             const Icon(
        //               Icons.lock_outline,
        //               size: 60,
        //               color: AppColors.errorRed,
        //             ),
        //             const SizedBox(height: 16),
        //             Text(
        //               'Akses Ditolak!',
        //               style: AppStyles.heading2.copyWith(
        //                 color: AppColors.errorRed,
        //               ),
        //             ),
        //             const SizedBox(height: 8),
        //             Text(
        //               'Halaman ini hanya dapat diakses oleh pengguna dengan peran BK atau Admin.',
        //               textAlign: TextAlign.center,
        //               style: AppStyles.bodyText1.copyWith(
        //                 color: AppColors.darkGrey,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   );
        // }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tugasku'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: reportProvider.isLoading ? null : _loadMyTasksData,
              ),
            ],
          ),
          body:
              reportProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportProvider.errorMessage != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.errorRed,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            reportProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyText1.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadMyTasksData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            child: Text(
                              'Coba Lagi',
                              style: AppStyles.buttonTextStyle.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    // Gunakan SingleChildScrollView untuk menggulir seluruh konten
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Bagian Statistik Dashboard ---
                        Text(
                          'Statistik Tugas Hari Ini',
                          style: AppStyles.heading2.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Ditugaskan Hari Ini',
                                count: reportProvider.assignedReportsTodayCount,
                                icon: Icons.assignment_turned_in,
                                color: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                title:
                                    'Laporan Diteruskan', // Atau "Laporan Selesai"
                                count: reportProvider.forwardedReportsCount,
                                icon: Icons.send,
                                color: AppColors.warningOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Bagian Daftar Laporan Ditugaskan ---
                        Text(
                          'Laporan Ditugaskan Kepada Anda',
                          style: AppStyles.heading2.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),

                        reportProvider.assignedReportsList.isEmpty
                            ? Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: AppColors.lightGrey,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'Tidak ada laporan yang ditugaskan kepada Anda.',
                                    style: AppStyles.bodyText2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap:
                                  true, // Penting agar ListView.builder bisa di dalam SingleChildScrollView
                              physics:
                                  const NeverScrollableScrollPhysics(), // Menonaktifkan scroll internal
                              itemCount:
                                  reportProvider.assignedReportsList.length,
                              itemBuilder: (context, index) {
                                final report =
                                    reportProvider.assignedReportsList[index];
                                return _buildAssignedReportListItem(
                                  context,
                                  report,
                                );
                              },
                            ),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  // Widget untuk kartu statistik (tetap sama)
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: AppStyles.heading1.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  // Widget baru atau modifikasi untuk setiap item laporan di daftar "Tugasku"
  Widget _buildAssignedReportListItem(BuildContext context, Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: AppStyles.heading3.copyWith(
                  color: AppColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Siswa: ${report.student?.name ?? 'N/A'} (${report.student?.studentClass?.name ?? 'N/A'})',
                      style: AppStyles.bodyText2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, size: 18, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Text(
                    'Tipe: ${report.reportType.toTitleCase()}',
                    style: AppStyles.bodyText2,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.priority_high,
                    size: 18,
                    color:
                        report.urgencyLevel == 'mendesak'
                            ? AppColors.darkGrey
                            : report.urgencyLevel == 'sedang'
                            ? AppColors
                                .warningOrange // Jika 'sedang', gunakan kuning
                            : AppColors.secondaryBlue,
                  ),

                  const SizedBox(width: 4),
                  Text(
                    'Urgensi: ${report.urgencyLevel.toTitleCase()}',
                    style:
                        report.urgencyLevel == 'mendesak'
                            ? TextStyle(
                              color: AppColors.errorRed,
                            ) // Jika 'mendesak', gunakan merah
                            : report.urgencyLevel == 'sedang'
                            ? TextStyle(
                              color: AppColors.warningOrange,
                            ) // Jika 'sedang', gunakan kuning
                            : TextStyle(
                              color: AppColors.secondaryBlue,
                            ), // Jika bukan keduanya (misal: 'rendah' atau default), gunakan biru
                  ),

                  // style: AppStyles.bodyText2,
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.assignment_ind,
                    size: 18,
                    color: AppColors.lightBlue,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Dibuat Oleh: ${report.reported_by!.name}',
                      style: AppStyles.bodyText2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (report.assignedToBk != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.assignment_ind,
                      size: 18,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ditugaskan ke: ${report.assignedToBk!.name}',
                        style: AppStyles.bodyText2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      report.status.toTitleCase(),
                      style: AppStyles.bodyText2.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    backgroundColor: _getStatusColor(report.status),
                  ),
                  Row(
                    children: [
                      Icon(Icons.comment, size: 18, color: AppColors.darkGrey),
                      const SizedBox(width: 4),
                      Text(
                        'Catatan: ${report.reportNotesCount ?? 0}', // Menampilkan jumlah notes
                        style: AppStyles.bodyText2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return AppColors.lightBlue;
      case 'dalam proses':
        return AppColors.warningOrange;
      case 'selesai':
        return AppColors.successGreen;
      default:
        return AppColors.darkGrey;
    }
  }
}
