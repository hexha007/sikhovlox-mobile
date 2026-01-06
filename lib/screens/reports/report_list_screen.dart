import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart'; // Import report detail
import 'package:intl/intl.dart'; // Untuk format tanggal

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch reports when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user?.role == 'wali_kelas') {
        Provider.of<ReportProvider>(
          context,
          listen: false,
        ).fetchReports(classId: user?.classId);
      } else {
        // Admin and BK roles
        Provider.of<ReportProvider>(context, listen: false).fetchReports();
      }
    });
  }

  Future<void> _refreshReports() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.role == 'wali_kelas') {
      // print('ini adalah user ${user?.role}');

      await Provider.of<ReportProvider>(
        context,
        listen: false,
      ).fetchReports(classId: user?.classId);
    } else {
      await Provider.of<ReportProvider>(context, listen: false).fetchReports();
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'sangat_tinggi':
        return AppColors.errorRed;
      case 'tinggi':
        return AppColors.warningOrange;
      case 'sedang':
        return AppColors.secondaryBlue;
      case 'rendah':
        return AppColors.successGreen;
      default:
        return AppColors.darkGrey;
    }
  }

  String _formatUrgency(String urgency) {
    return StringExtension(urgency.replaceAll('_', ' ')).toCapitalized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Daftar Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _refreshReports,
          ),
          // Tombol tambah laporan (opsional, tergantung peran)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buat Laporan Baru',
            onPressed: () {
              Navigator.pushNamed(context, '/add_report_select_student').then((
                result,
              ) {
                if (result == true) {
                  // Refresh laporan setelah laporan berhasil dibuat
                  Provider.of<ReportProvider>(
                    context,
                    listen: false,
                  ).fetchReports();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  reportProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.errorRed, fontSize: 16),
                ),
              ),
            );
          }

          if (reportProvider.reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data laporan.',
                    style: TextStyle(color: AppColors.darkGrey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshReports,
            color: AppColors.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reportProvider.reports.length,
              itemBuilder: (context, index) {
                final report = reportProvider.reports[index];
                return _buildReportCard(context, report);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(
                        report.urgencyLevel,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatUrgency(report.urgencyLevel),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getUrgencyColor(report.urgencyLevel),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Siswa: ${report.student?.name ?? 'N/A'} (${report.student?.studentClass?.name ?? 'N/A'})',
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipe: ${report.reportType}',
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${StringExtension(report.status).toCapitalized()}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      report.status == 'baru'
                          ? AppColors.errorRed
                          : (report.status == 'ditangani'
                              ? AppColors.secondaryBlue
                              : AppColors.successGreen),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Pelapor: ${report.reported_by?.name ?? 'N/A'} ',
                  style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Ditugaskan: ${report.assignedToBk?.name ?? 'N/A'} ',
                  style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension untuk kapitalisasi string (jika belum ada)
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
