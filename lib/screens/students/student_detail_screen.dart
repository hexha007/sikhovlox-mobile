import 'package:flutter/material.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:intl/intl.dart'; // Pastikan sudah menambahkan intl di pubspec.yaml

class StudentDetailScreen extends StatelessWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text(student.name),
        // Tambahkan tombol edit siswa jika diperlukan
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Siswa',
            onPressed: () {
              // Navigasi ke halaman edit siswa
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header dengan foto/ikon siswa
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        student.gender == 'L'
                            ? AppColors.lightBlue
                            : AppColors.primaryBlue.withOpacity(0.7),
                    child: Icon(
                      student.gender == 'L' ? Icons.male : Icons.female,
                      color: AppColors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'NIS: ${student.nis}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard('Informasi Umum', [
              _buildInfoRow(
                'Kelas',
                student.studentClass?.name ?? 'N/A',
                Icons.school,
              ),
              _buildInfoRow(
                'Jenis Kelamin',
                student.gender == 'L' ? 'Laki-laki' : 'Perempuan',
                student.gender == 'L' ? Icons.male : Icons.female,
              ),
              _buildInfoRow(
                'Tanggal Lahir',
                student.birthDate != null
                    ? DateFormat('dd MMMM yyyy').format(student.birthDate!)
                    : 'N/A',
                Icons.cake,
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Detail Kontak & Alamat', [
              _buildInfoRow(
                'No. Telp Orang Tua',
                student.parentPhone ?? 'N/A',
                Icons.phone,
              ),
              _buildInfoRow('Alamat', student.address ?? 'N/A', Icons.home),
            ]),
            // Anda bisa menambahkan bagian lain, misalnya daftar laporan terkait siswa ini
            const SizedBox(height: 16),
            _buildInfoCard('Laporan Terkait', [
              // Daftar laporan di sini
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryBlue,
              ),
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: AppColors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
