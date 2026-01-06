import 'package:flutter/material.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/models/user.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/providers/user_provider.dart';
import 'package:nebeng_app/utils/loading_indicator.dart';
import 'package:provider/provider.dart';

import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

class AddReportScreen extends StatefulWidget {
  final List<Student> selectedStudents;

  const AddReportScreen({super.key, required this.selectedStudents});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _expectationController = TextEditingController();

  String? _selectedReportType;
  String? _selectedUrgencyLevel;
  User? _selectedAssignedBk; // Untuk menyimpan petugas BK yang dipilih
  int? _classIdForBkFilter;

  final List<String> _reportTypes = [
    'akademik',
    'perilaku',
    'sosial',
    'emosional',
    'lainnya',
  ];

  final List<String> _urgencyLevels = ['mendesak', 'sedang', 'rendah'];

  @override
  void initState() {
    super.initState();
    if (widget.selectedStudents.isNotEmpty) {
      _classIdForBkFilter = widget.selectedStudents.first.studentClass?.id;
    }

    // Panggil fetchBkUsers dengan classId yang sudah didapatkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).fetchBkUsers(_classIdForBkFilter);
    });
  }

  Future<void> _submitReport() async {
    // Check if any student is selected
    if (widget.selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one student to create a report.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report type must be selected.')),
      );
      return;
    }
    if (_selectedUrgencyLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Urgency level must be selected.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please log in again.'),
        ),
      );
      return;
    }

    // reportProvider.setLoading(true); // Manually set loading state

    List<Future<void>> addReportFutures = [];
    for (var student in widget.selectedStudents) {
      final newReport = Report(
        studentId: student.id!,
        title: _titleController.text,
        description: _descriptionController.text,
        reportType: _selectedReportType!,
        urgencyLevel: _selectedUrgencyLevel!,
        // Use current user's ID
        createdAt:
            DateTime.now(), // Client-side timestamp, backend should generate this
        updatedAt: DateTime.now(),
        id: 1,
        status: 'Baru',
        created_by_id: 1,
        assignedToBkId:
            _selectedAssignedBk!
                .id, // Client-side timestamp, backend should generate this
      );
      addReportFutures.add(
        reportProvider.addReport(newReport),
      ); // Use createReport
    }

    try {
      await Future.wait(addReportFutures); // Wait for all reports to be created

      if (reportProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added ${widget.selectedStudents.length} report(s)!',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop(true); // Indicate success and pop
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add report: ${reportProvider.errorMessage}',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      // reportProvider.setLoading(false); // Ensure loading state is reset
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionsTakenController.dispose();
    _expectationController.dispose();
    // Removed classIdwalas related debug print and variable, as it's not needed for disposal.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(
      context,
    ); // Access AuthProvider

    final currentUser = authProvider.user; // Get the logged-in user

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body:
          reportProvider.isLoading
              ? const LoadingIndicator(message: 'Mengirim laporan...')
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Display Reporter (Wali Kelas) ---
                      if (currentUser != null)
                        _buildInfoRow(
                          label: 'Pelapor (Wali Kelas):',
                          value: currentUser.name,
                          icon: Icons.person,
                        ),
                      const SizedBox(height: 16),
                      Text('Siswa Terpilih:', style: AppStyles.heading3),
                      const SizedBox(height: 8),
                      // Display selected students
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children:
                            widget.selectedStudents.map((student) {
                              // Removed setState here to prevent infinite loop
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor:
                                      student.gender == 'L'
                                          ? AppColors.lightBlue
                                          : AppColors.primaryBlue.withOpacity(
                                            0.7,
                                          ),
                                  child: Icon(
                                    student.gender == 'L'
                                        ? Icons.male
                                        : Icons.female,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ),
                                label: Text(
                                  '${student.name} (${student.studentClass?.name ?? 'N/A'})',
                                  style: AppStyles.bodyText2.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                                backgroundColor: AppColors.mediumGrey
                                    .withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Display selected BK if any
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

                      // Dropdown for selecting BK personnel from UserProvider
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
                              reportProvider.isLoading ? null : _submitReport,
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
                                ? 'Sending...'
                                : 'Create Report',
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

  // Helper widget for displaying info rows
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

// Extension for string capitalization (if not already defined)
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');
}
