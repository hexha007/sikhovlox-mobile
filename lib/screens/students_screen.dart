// lib/screens/students_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/screens/student_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/student_provider.dart'; // Asumsi ini ada
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:shimmer/shimmer.dart'; // Asumsi ada model Student

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // Anda bisa menambahkan TextEditingController untuk pencarian siswa di sini jika diperlukan
  // final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(
        context,
        listen: false,
      ).fetchStudents_siswaku();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final currentUser = authProvider.user;
            if (currentUser?.role == 'wali_kelas' &&
                currentUser?.classId != null) {
              debugPrint('ini adalah kelas ${jsonEncode(currentUser)}');
              return Text('Siswa Kelas ${currentUser?.class_name}');
            }
            return const Text('Daftar Siswa'); // Untuk BK/Admin
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () =>
                    Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    ).fetchStudents_siswaku(),
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return _buildShimmerLoading(); // Tampilan loading modern
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
                      onPressed: () => studentProvider.fetchStudents_siswaku(),
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

          if (studentProvider.students.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada siswa ditemukan.',
                style: AppStyles.bodyText1.copyWith(color: AppColors.darkGrey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: studentProvider.students.length,
            itemBuilder: (context, index) {
              final student = studentProvider.students[index];
              return _buildStudentCard(context, student);
            },
          );
        },
      ),
    );
  }

  // Widget untuk setiap kartu siswa
  Widget _buildStudentCard(BuildContext context, Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 6, // Elevasi lebih tinggi untuk efek modern
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Sudut membulat
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigasi ke halaman detail siswa atau daftar laporan siswa ini
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(studentId: student.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: AppStyles.heading3.copyWith(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.nis,
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.studentClass?.name ?? 'Kelas Tidak Diketahui',
                          style: AppStyles.bodyText2.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.lightGrey),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    icon: Icons.assignment,
                    label: 'Jumlah Laporan',
                    value: student.reportsCount?.toString() ?? '0',
                    color: AppColors.primaryBlue,
                  ),
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Laporan Terakhir',
                    value:
                        student.latestReportDate != null
                            ? DateFormat(
                              'dd MMM yyyy',
                            ).format(student.latestReportDate!)
                            : 'Belum Ada',
                    color: AppColors.warningOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pembantu untuk item statistik di dalam card siswa
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppStyles.bodyText2.copyWith(color: AppColors.darkGrey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.heading3.copyWith(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Skeleton Loader (Shimmer effect)
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Jumlah item skeleton
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                            ),
                            Container(
                              height: 14,
                              width: 100,
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 4),
                            ),
                            Container(
                              height: 14,
                              width: 150,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 14,
                            width: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(height: 20, width: 50, color: Colors.white),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            height: 14,
                            width: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(height: 20, width: 50, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
