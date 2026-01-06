import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/models/user.dart'; // Untuk model User (BK Personnel)
import 'package:nebeng_app/models/student.dart'; // Untuk model Student (jika ingin menampilkan detailnya)
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/providers/user_provider.dart'; // Untuk fetch BK users
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';
import 'package:nebeng_app/utils/loading_indicator.dart'; // Jika ada widget loading
import 'package:nebeng_app/providers/auth_provider.dart'; // Untuk user saat ini

class EditReportScreen extends StatefulWidget {
  final int reportId;

  const EditReportScreen({super.key, required this.reportId});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _expectationController = TextEditingController();

  String? _selectedReportType;
  String? _selectedUrgencyLevel;
  String? _selectedStatus; // Tambahkan untuk status
  User? _selectedAssignedBk;

  Report? _initialReportData; // Untuk menyimpan data asli laporan
  Student? _studentOfReport; // Untuk menyimpan data siswa terkait laporan

  final List<String> _reportTypes = [
    'akademik',
    'perilaku',
    'sosial',
    'emosional',
    'lainnya',
  ];

  final List<String> _urgencyLevels = ['mendesak', 'sedang', 'rendah'];
  final List<String> _statuses = [
    'Baru',
    'Dalam Proses',
    'Selesai',
  ]; // Daftar status

  @override
  void initState() {
    super.initState();
    // Memuat data laporan dan menginisialisasi controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final report = await reportProvider.getReportById(widget.reportId);
      // print("ini data yang akan di edit${jsonEncode(report)}");
      if (report != null) {
        setState(() {
          _initialReportData = report; // Simpan data awal
          _titleController.text = report.title;
          _descriptionController.text = report.description;
          // _actionsTakenController.text = report.actionsTakenByReporter ?? '';
          // _expectationController.text = report.expectationFromBk ?? '';
          _selectedReportType = report.reportType;
          _selectedUrgencyLevel = report.urgencyLevel;
          _selectedStatus = report.status; // Inisialisasi status

          // Inisialisasi petugas BK
          debugPrint(
            'ini adalah id report ${report.assignedToBkId.toString()}',
          );
          if (report.assignedToBkId != null) {
            // Asumsi userProvider sudah punya list bkUsers
            // atau ada method untuk fetch single user by ID

            _selectedAssignedBk = userProvider.bkUsers.firstWhereOrNull(
              (user) => user.id == report.assignedToBkId,
            );
          }
          // Ambil detail siswa terkait laporan
          _studentOfReport =
              report
                  .student; // Asumsi relasi student sudah diload di backend/model
        });

        // Setelah mendapatkan data laporan, baru panggil BK users dengan filter kelas siswa
        // Asumsi report.student memiliki properti class_id
        final classIdForBkFilter =
            _initialReportData!
                .student
                ?.classId; // Atur studentId sebagai filter
        await userProvider.fetchBkUsers(classIdForBkFilter);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load report data.')),
        );
        Navigator.of(context).pop(); // Kembali jika data tidak ditemukan
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading report: $e')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReportType == null ||
        _selectedUrgencyLevel == null ||
        _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All dropdowns must be selected.')),
      );
      return;
    }

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    // Buat objek Report baru dengan data yang diperbarui
    final updatedReport = _initialReportData!.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      reportType: _selectedReportType!,
      urgencyLevel: _selectedUrgencyLevel!,
      actionsTakenByReporter:
          _actionsTakenController.text.isEmpty
              ? null
              : _actionsTakenController.text,
      expectationFromBk:
          _expectationController.text.isEmpty
              ? null
              : _expectationController.text,
      assignedToBkId: _selectedAssignedBk?.id,
      status: _selectedStatus!, // Update status
      updatedAt: DateTime.now(), // Perbarui timestamp
    );

    try {
      await reportProvider.updateReport(widget.reportId, updatedReport);

      if (reportProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report updated successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop(true); // Pop dan berikan indikasi sukses
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update report: ${reportProvider.errorMessage}',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during update: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionsTakenController.dispose();
    _expectationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    // Tampilkan loading jika data laporan belum dimuat
    if (_initialReportData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Laporan'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Laporan'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body:
          reportProvider.isLoading
              ? const LoadingIndicator(message: 'Menyimpan perubahan...')
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentUser != null)
                        _buildInfoRow(
                          label: 'Pelapor (Wali Kelas):',
                          value: currentUser.name,
                          icon: Icons.person,
                        ),
                      const SizedBox(height: 16),
                      Text('Siswa Terkait:', style: AppStyles.heading3),
                      const SizedBox(height: 8),
                      // Menampilkan chip untuk siswa terkait
                      // Asumsi _studentOfReport sudah dimuat
                      if (_studentOfReport != null)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor:
                                _studentOfReport!.gender == 'L'
                                    ? AppColors.lightBlue
                                    : AppColors.primaryBlue.withOpacity(0.7),
                            child: Icon(
                              _studentOfReport!.gender == 'L'
                                  ? Icons.male
                                  : Icons.female,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                          label: Text(
                            '${_studentOfReport!.name} (${_studentOfReport!.studentClass?.name ?? 'N/A'})',
                            style: AppStyles.bodyText2.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          backgroundColor: AppColors.mediumGrey.withOpacity(
                            0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_selectedAssignedBk != null)
                        _buildInfoRow(
                          label: 'Petugas BK Ditugaskan:',
                          value: _selectedAssignedBk!.name,
                          icon: Icons.person_add,
                        ),
                      const SizedBox(height: 24),
                      Text('Detail Laporan', style: AppStyles.heading3),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: AppStyles.standardInputDecoration(
                          labelText: 'Judul Laporan',
                          prefixIcon: Icons.title,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul laporan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: AppStyles.standardInputDecoration(
                          labelText: 'Deskripsi Laporan',
                          prefixIcon: Icons.description,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi laporan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedReportType,
                        decoration: AppStyles.standardInputDecoration(
                          labelText: 'Tipe Laporan',
                          prefixIcon: Icons.category,
                        ),
                        hint: const Text('Pilih Tipe Laporan'),
                        items:
                            _reportTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.replaceAll('_', ' ').toTitleCase(),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReportType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tipe laporan harus dipilih';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedUrgencyLevel,
                        decoration: AppStyles.standardInputDecoration(
                          labelText: 'Tingkat Urgensi',
                          prefixIcon: Icons.priority_high,
                        ),
                        hint: const Text('Pilih Tingkat Urgensi'),
                        items:
                            _urgencyLevels.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level.replaceAll('_', ' ').toTitleCase(),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUrgencyLevel = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tingkat urgensi harus dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      userProvider.isLoadingBkUsers
                          ? const Center(child: CircularProgressIndicator())
                          : userProvider.bkUsersErrorMessage != null
                          ? Text(
                            'Error loading BK personnel: ${userProvider.bkUsersErrorMessage}',
                          )
                          : DropdownButtonFormField<User>(
                            decoration: AppStyles.standardInputDecoration(
                              labelText: 'Assign to BK Personnel (Optional)',
                              prefixIcon: Icons.person_add,
                            ),
                            value: _selectedAssignedBk,
                            hint: const Text('Select BK Personnel'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Not Assigned Yet'),
                              ),
                              ...userProvider.bkUsers.map((bkUser) {
                                return DropdownMenuItem<User>(
                                  value: bkUser,
                                  child: Text(bkUser.name),
                                );
                              }).toList(),
                            ],
                            onChanged: (User? value) {
                              setState(() {
                                _selectedAssignedBk = value;
                              });
                            },
                          ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              reportProvider.isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            reportProvider.isLoading
                                ? 'Saving...'
                                : 'Save Changes',
                            style: AppStyles.buttonTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppStyles.bodyText2.copyWith(color: AppColors.darkGrey),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tambahkan jika belum ada, untuk membantu mencari user
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
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
