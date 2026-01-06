// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:nebeng_app/screens/reports/edit_report_screen.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter;
  final List<String> _statusOptions = [
    'Semua',
    'Baru',
    'Dalam Proses',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportsBasedOnRole();
    });

    _searchController.addListener(() {
      if (_searchController.text.isEmpty || _searchController.text.length > 2) {
        _loadReportsBasedOnRole();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsBasedOnRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      debugPrint("User is null, cannot load reports.");
      return;
    }

    final String? currentSearchQuery =
        _searchController.text.isNotEmpty ? _searchController.text : null;
    final String? currentStatusFilter =
        _selectedStatusFilter == 'Semua' ? null : _selectedStatusFilter;

    // if (user.role == 'wali_kelas') {
    //   debugPrint('Loading reports for Wali Kelas, classId: ${user.classId}');
    //   await reportProvider.fetchReports(
    //     classId: user.classId,
    //     searchQuery: currentSearchQuery,
    //     statusFilter: currentStatusFilter,
    //   );
    // } else if (user.role == 'BK') {
    //   debugPrint('Loading reports for BK user: ${user.id}');
    //   await reportProvider.fetchReports(
    //     searchQuery: currentSearchQuery,
    //     statusFilter: currentStatusFilter,
    //   );
    // } else if (user.role == 'admin') {
    //   debugPrint('Loading all reports for Admin.');
    //   await reportProvider.fetchReports(
    //     searchQuery: currentSearchQuery,
    //     statusFilter: currentStatusFilter,
    //   );
    // } else {
    //   debugPrint('User role unknown: ${user.role}. Not fetching reports.');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUser = authProvider.user;

        String pageTitle = 'Laporanku';
        if (currentUser?.role == 'wali_kelas') {
          pageTitle = 'Laporan Kelas ${currentUser?.classId ?? ''}';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    reportProvider.isLoading ? null : _loadReportsBasedOnRole,
              ),
            ],
          ),
          body: Column(
            children: [
              // Bagian Pencarian dan Filter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      decoration: AppStyles.standardInputDecoration(
                        labelText: 'Cari Laporan...',
                        prefixIcon: Icons.search,
                        // suffixIcon:
                        //     _searchController.text.isNotEmpty
                        //         ? IconButton(
                        //           icon: const Icon(Icons.clear),
                        //           onPressed: () {
                        //             _searchController.clear();
                        //             _loadReportsBasedOnRole();
                        //           },
                        //         )
                        //         : null,
                      ),
                      onFieldSubmitted: (value) {
                        _loadReportsBasedOnRole();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatusFilter,
                      decoration: AppStyles.standardInputDecoration(
                        labelText: 'Filter Status',
                        prefixIcon: Icons.filter_list,
                      ),
                      hint: const Text('Semua Status'),
                      items:
                          _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.toTitleCase()),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _loadReportsBasedOnRole();
                      },
                    ),
                  ],
                ),
              ),

              // Bagian Daftar Laporan Utama
              Expanded(
                child:
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
                                  onPressed: _loadReportsBasedOnRole,
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
                        : reportProvider.reports.isEmpty
                        ? Center(
                          child: Text(
                            'Tidak ada laporan yang sesuai.',
                            style: AppStyles.bodyText1.copyWith(
                              color: AppColors.darkGrey,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: reportProvider.reports.length,
                          itemBuilder: (context, index) {
                            final report = reportProvider.reports[index];
                            return _buildReportListItem(context, report);
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

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
              Align(
                alignment: Alignment.bottomRight,
                child: Chip(
                  label: Text(
                    report.status.toTitleCase(),
                    style: AppStyles.bodyText2.copyWith(color: AppColors.white),
                  ),
                  backgroundColor: _getStatusColor(report.status),
                ),
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
