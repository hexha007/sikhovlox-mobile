// lib/screens/my_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';
// Untuk navigasi ke detail laporan

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Filter values
  String? _selectedStatus = 'all'; // Default: all
  String? _selectedReportType = 'all';
  String? _selectedUrgencyLevel = 'all';

  final List<String> _statusOptions = ['all', 'baru', 'ditangani', 'selesai'];
  final List<String> _reportTypeOptions = [
    'all',
    'akademik',
    'perilaku',
    'sosial',
    'emosional',
    'lainnya',
  ]; // Sesuaikan dengan tipe laporan Anda
  final List<String> _urgencyLevelOptions = [
    'all',
    'mendesak',
    'sedang',
    'rendah',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMyReports(); // Initial fetch
    });
    _searchController.addListener(() {
      // Debounce search input to avoid too frequent API calls
      if (_searchController.text.isEmpty || _searchController.text.length > 2) {
        // Fetch if empty or > 2 chars
        _debounceSearch();
      }
    });
  }

  // Debounce timer for search
  VoidCallback? _debouncedSearchCallback;
  void _debounceSearch() {
    if (_debouncedSearchCallback != null) {
      _debouncedSearchCallback!(); // Cancel previous debounce
    }
    _debouncedSearchCallback = () {
      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchMyReports();
        _debouncedSearchCallback = null;
      });
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    await reportProvider.fetchMyReports(
      status: _selectedStatus,
      reportType: _selectedReportType,
      urgencyLevel: _selectedUrgencyLevel,
      searchQuery: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporanku'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            120.0,
          ), // Tinggi untuk search bar dan filters
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari laporan (judul/deskripsi)...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.darkGrey,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.darkGrey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _fetchMyReports(); // Fetch again after clearing search
                              },
                            )
                            : null,
                  ),
                  onSubmitted:
                      (_) => _fetchMyReports(), // Trigger search on submit
                ),
                const SizedBox(height: 8),
                // Filter Dropdowns
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown(
                        label: 'Status',
                        value: _selectedStatus,
                        options: _statusOptions,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                          _fetchMyReports();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        label: 'Tipe',
                        value: _selectedReportType,
                        options: _reportTypeOptions,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedReportType = newValue;
                          });
                          _fetchMyReports();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        label: 'Urgensi',
                        value: _selectedUrgencyLevel,
                        options: _urgencyLevelOptions,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedUrgencyLevel = newValue;
                          });
                          _fetchMyReports();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return _buildShimmerLoading(); // Skeleton loader
          }

          if (reportProvider.errorMessage != null) {
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
                      reportProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchMyReports,
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

          if (reportProvider.myReportsList.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada laporan yang Anda buat sesuai kriteria.',
                style: AppStyles.bodyText1.copyWith(color: AppColors.darkGrey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reportProvider.myReportsList.length,
            itemBuilder: (context, index) {
              final report = reportProvider.myReportsList[index];
              return _buildReportListItem(context, report);
            },
          );
        },
      ),
    );
  }

  // Widget pembantu untuk dropdown filter
  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          style: AppStyles.bodyText2.copyWith(color: AppColors.darkBlue),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkGrey),
          onChanged: onChanged,
          items:
              options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option.toTitleCase()),
                );
              }).toList(),
        ),
      ),
    );
  }

  // Widget untuk setiap item laporan di daftar "Laporanku" (mirip AssignedReportsScreen)
  Widget _buildReportListItem(BuildContext context, Report report) {
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
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Urgensi: ${report.urgencyLevel.toTitleCase()}',
                    style: AppStyles.bodyText2,
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
                      color: AppColors.darkGrey,
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
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.darkGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}',
                    style: AppStyles.bodyText2,
                    overflow: TextOverflow.ellipsis,
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
                        'Catatan: ${report.reportNotesCount ?? 0}',
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

  // Skeleton Loader (mirip dengan yang sudah ada)
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
    );
  }
}

// Extension for String toTitleCase (if not already defined)
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => StringExtension(str).toCapitalized()).join(' ');
}
