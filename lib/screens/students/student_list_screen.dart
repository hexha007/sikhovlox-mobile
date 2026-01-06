import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/student_provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/screens/students/student_detail_screen.dart'; // Import student detail

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch students when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user?.role == 'wali_kelas') {
        Provider.of<StudentProvider>(
          context,
          listen: false,
        ).fetchStudents(classId: user?.classId);
      } else {
        Provider.of<StudentProvider>(context, listen: false).fetchStudents();
      }
    });
  }

  Future<void> _refreshStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.role == 'wali_kelas') {
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).fetchStudents(classId: user?.classId);
    } else {
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).fetchStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Daftar Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _refreshStudents,
          ),
          // Tambahkan tombol tambah siswa jika diperlukan (misal untuk Admin/BK/Wali Kelas)
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   tooltip: 'Tambah Siswa',
          //   onPressed: () {
          //     // Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddStudentScreen()));
          //   },
          // ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  studentProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.errorRed, fontSize: 16),
                ),
              ),
            );
          }

          if (studentProvider.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: AppColors.darkGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data siswa.',
                    style: TextStyle(color: AppColors.darkGrey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshStudents,
            color: AppColors.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: studentProvider.students.length,
              itemBuilder: (context, index) {
                final student = studentProvider.students[index];
                return _buildStudentCard(context, student);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(student: student),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    student.gender == 'L'
                        ? AppColors.lightBlue
                        : AppColors.primaryBlue.withOpacity(0.7),
                child: Icon(
                  student.gender == 'L' ? Icons.male : Icons.female,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS: ${student.nis}',
                      style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                    ),
                    if (student.studentClass != null)
                      Text(
                        'Kelas: ${student.studentClass!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGrey,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.darkGrey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
