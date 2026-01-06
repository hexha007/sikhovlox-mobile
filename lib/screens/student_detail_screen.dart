// lib/screens/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:nebeng_app/screens/reports/edit_report_screen.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nebeng_app/providers/student_provider.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';
// Untuk navigasi ke detail laporan

class StudentDetailScreen extends StatefulWidget {
  final int studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    await Provider.of<StudentProvider>(
      context,
      listen: false,
    ).fetchStudentDetail(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchData(),
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return _buildShimmerLoading(); // Skeleton loader
          }

          if (studentProvider.errorMessage != null) {
            return Center(
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
                      studentProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _fetchData(),
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
            );
          }

          final student = studentProvider.selectedStudent;
          final reports = studentProvider.studentReports;

          if (student == null) {
            return Center(
              child: Text(
                'Data siswa tidak ditemukan.',
                style: AppStyles.bodyText1.copyWith(color: AppColors.darkGrey),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Informasi Siswa
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.lightBlue,
                                child: Text(
                                  student.name[0].toUpperCase(),
                                  style: AppStyles.heading1.copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: AppStyles.heading2.copyWith(
                                        color: AppColors.darkBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      student.nis,
                                      style: AppStyles.bodyText1.copyWith(
                                        color: AppColors.darkGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      student.studentClass?.name ??
                                          'Kelas Tidak Diketahui',
                                      style: AppStyles.bodyText1.copyWith(
                                        color: AppColors.darkGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.assignment,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Total Laporan: ${student.reportsCount ?? '0'}',
                                          style: AppStyles.bodyText2.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: AppColors.warningOrange,
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.4,
                                          child: Text(
                                            'Laporan Terakhir: ${student.latestReportDate != null ? DateFormat('dd MMM yyyy').format(student.latestReportDate!) : 'Belum Ada'}',
                                            style: AppStyles.bodyText2.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Daftar Laporan',
                        style: AppStyles.heading2.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Daftar Laporan Siswa
              reports.isEmpty
                  ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Siswa ini belum memiliki laporan.',
                        style: AppStyles.bodyText1.copyWith(
                          color: AppColors.darkGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final report = reports[index];
                      return _buildReportCard(context, report);
                    }, childCount: reports.length),
                  ),
            ],
          );
        },
      ),
    );
  }

  // Widget untuk setiap kartu laporan
  Widget _buildReportCard(BuildContext context, Report report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: AppStyles.heading3.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 18, color: AppColors.darkGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipe: ${report.reportType.toTitleCase()}',
                      style: AppStyles.bodyText2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 18,
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Urgensi: ${report.urgencyLevel.toTitleCase()}',
                      style: AppStyles.bodyText2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tanggal: ${DateFormat('dd MMM yyyy').format(report.createdAt)}',
                      style: AppStyles.bodyText2,
                    ),
                  ),
                ],
              ),
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

  // Skeleton Loader untuk StudentDetailScreen
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton untuk Header Info Siswa
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                          ),
                          Container(
                            height: 16,
                            width: 150,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 4),
                          ),
                          Container(
                            height: 16,
                            width: 180,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                          ),
                          Container(
                            height: 14,
                            width: 100,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 4),
                          ),
                          Container(
                            height: 14,
                            width: 120,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 20,
              width: 150,
              color: Colors.white,
            ), // Skeleton untuk "Daftar Laporan"
            const SizedBox(height: 12),
            // Skeleton untuk Daftar Laporan
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Jumlah skeleton laporan
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: double.infinity,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Container(
                          height: 14,
                          width: 200,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                        Container(
                          height: 14,
                          width: 150,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                        Container(
                          height: 14,
                          width: 180,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            height: 28,
                            width: 80,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
