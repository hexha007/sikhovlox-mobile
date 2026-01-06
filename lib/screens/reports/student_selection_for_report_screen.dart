import 'package:flutter/material.dart';
import 'package:nebeng_app/providers/student_class_provider.dart';
import 'package:nebeng_app/utils/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/models/student_class.dart'; // Import StudentClass
import 'package:nebeng_app/providers/student_provider.dart'; // Import StudentClassProvider
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

import 'package:nebeng_app/widgets/empty_state_widget.dart';
import 'package:nebeng_app/screens/reports/add_report_screen.dart'; // Import AddReportScreen

class StudentSelectionForReportScreen extends StatefulWidget {
  const StudentSelectionForReportScreen({super.key});

  @override
  State<StudentSelectionForReportScreen> createState() =>
      _StudentSelectionForReportScreenState();
}

class _StudentSelectionForReportScreenState
    extends State<StudentSelectionForReportScreen> {
  final ScrollController _scrollController =
      ScrollController(); // Tambahkan ini

  StudentClass? _selectedClassFilter;
  List<Student> _selectedStudents = [];
  bool _isLoadingData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Muat daftar kelas dan siswa saat inisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });

    // Tambahkan listener untuk scroll
    _scrollController.addListener(_onScroll);
  }

  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose(); // Penting untuk dispose controller
    super.dispose();
  }

  Future<void> _fetchInitialData({int? classId}) async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });
    try {
      // Perbaikan di sini: Gunakan listen: false ketika memanggil Provider.of di initState/async method
      final studentClassProvider = Provider.of<StudentClassProvider>(
        context,
        listen: false,
      );
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );

      await studentClassProvider.fetchStudentClasses();
      await studentProvider.fetchStudentsall(
        refresh: true,
        classId: classId,
      ); // <-- Kirim classId di sini
      // Muat halaman pertama
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        debugPrint('Error fetching initial data for student selection: $e');
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _onScroll() {
    // Cek apakah scroll sudah mendekati akhir
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      // Jika masih ada data dan belum dalam proses fetching
      if (studentProvider.hasMoreData && !studentProvider.isFetchingMore) {
        studentProvider.fetchNextPageOfStudents();
      }
    }
  }

  void _onStudentSelected(Student student, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedStudents.add(student);
      } else {
        _selectedStudents.removeWhere((s) => s.id == student.id);
      }
    });
  }

  void _navigateToCreateReport() {
    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap pilih minimal satu siswa untuk membuat laporan.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddReportScreen(selectedStudents: _selectedStudents),
      ),
    ).then((result) {
      // Jika AddReportScreen berhasil membuat laporan, bersihkan pilihan dan refresh
      if (result == true) {
        setState(() {
          _selectedStudents.clear();
          _selectedClassFilter = null; // Reset filter
        });
        _fetchInitialData(); // Refresh data siswa jika ada perubahan
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final studentClassProvider = Provider.of<StudentClassProvider>(context);

    List<Student> displayedStudents =
        studentProvider.students.where((student) {
          return _selectedClassFilter == null ||
              student.classId == _selectedClassFilter!.id;
        }).toList();

    // print(studentClassProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Siswa untuk Laporan')),
      body:
          _isLoadingData
              ? const LoadingIndicator(
                message: 'Memuat data siswa dan kelas...',
              )
              : _errorMessage != null
              ? EmptyStateWidget(
                message: _errorMessage!,
                icon: Icons.error_outline,
                onRefresh: _fetchInitialData,
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Berdasarkan Kelas:',
                          style: AppStyles.subHeading,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<StudentClass>(
                          decoration: AppStyles.standardInputDecoration(
                            labelText: 'Pilih Kelas',
                            prefixIcon: Icons.class_,
                          ),
                          value: _selectedClassFilter,
                          hint: const Text('Semua Kelas'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Semua Kelas'),
                            ),
                            ...studentClassProvider.studentClasses.map((
                              sClass,
                            ) {
                              return DropdownMenuItem(
                                value: sClass,
                                child: Text(sClass.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (StudentClass? value) {
                            // Pastikan tipe `value` adalah StudentClass?
                            setState(() {
                              _selectedClassFilter = value;
                              _selectedStudents.clear();
                            });
                            debugPrint(
                              'Nilai _selectedClassFilter saat ini: ${_selectedClassFilter?.name} (ID: ${_selectedClassFilter?.id})',
                            );
                            _fetchInitialData(classId: value?.id);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Jumlah Siswa Terpilih: ${_selectedStudents.length}',
                          style: AppStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        displayedStudents.isEmpty
                            ? const EmptyStateWidget(
                              message: 'Tidak ada siswa ditemukan.',
                              icon: Icons.person_off,
                              subMessage:
                                  'Coba ubah filter kelas atau tambahkan siswa baru.',
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              itemCount: displayedStudents.length,
                              itemBuilder: (context, index) {
                                final student = displayedStudents[index];
                                final isSelected = _selectedStudents.contains(
                                  student,
                                );
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation:
                                      isSelected ? 6 : 2, // Animasi elevation
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side:
                                        isSelected
                                            ? const BorderSide(
                                              color: AppColors.secondaryBlue,
                                              width: 2,
                                            )
                                            : BorderSide.none,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () {
                                      _onStudentSelected(student, !isSelected);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                AppColors.lightBlue,
                                            child: Icon(
                                              student.gender == 'L'
                                                  ? Icons.male
                                                  : Icons.female,
                                              color: AppColors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.name,
                                                  style: AppStyles.subHeading
                                                      .copyWith(
                                                        color: AppColors.black,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'NIS: ${student.nis} | Kelas: ${student.studentClass?.name ?? 'N/A'}',
                                                  style: AppStyles.smallText,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? newValue) {
                                              _onStudentSelected(
                                                student,
                                                newValue ?? false,
                                              );
                                            },
                                            activeColor: AppColors.primaryBlue,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCreateReport,
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.white,
                        ),
                        label: Text(
                          'Lanjutkan (${_selectedStudents.length} Siswa Terpilih)',
                          style: AppStyles.buttonTextStyle,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
