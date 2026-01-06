import 'package:flutter/material.dart';
import 'package:nebeng_app/models/ReportNote.dart';
import 'package:nebeng_app/models/report.dart';
import 'package:nebeng_app/models/user.dart';
import 'package:nebeng_app/providers/report_note_provider.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/screens/reports/add_report_note_screen.dart';
import 'package:nebeng_app/screens/reports/edit_report_screen.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nebeng_app/config/app_constants.dart';
import 'package:nebeng_app/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Report _currentReport;

  bool _isLoadingNotes = false;
  String? _notesErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _fetchReportDetails(); // Fetch full details including notes
  }

  // void _showAddNoteDialog({required int reportId}) async {
  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AddReportNoteDialog(reportId: reportId);
  //     },
  //   );

  //   if (result == true) {
  //     // Jika catatan berhasil ditambahkan, refresh data laporan dan catatan
  //     _fetchReportDetails();
  //   }
  // }

  Future<void> _showForwardConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Teruskan ke BK'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Anda yakin ingin meneruskan laporan ini ke BK?'),
                Text('Status laporan akan diubah menjadi "Diteruskan ke BK".'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Ya, Teruskan'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                await _forwardReportToBk(context); // Call the forward function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _forwardReportToBk(BuildContext context) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    bool success = await reportProvider.forwardReportToBk(widget.report.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil diteruskan ke BK!')),
      );
      // Refresh detail laporan setelah berhasil diteruskan
      // _fetchReportDetailsAndNotes();
      _fetchReportDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reportProvider.errorMessage ?? 'Gagal meneruskan laporan ke BK.',
          ),
        ),
      );
    }
  }

  void _showCloseReportDialog() async {
    final conclusionController = TextEditingController();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Tutup Laporan',
            style: AppStyles.heading3.copyWith(color: AppColors.primaryBlue),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apakah Anda yakin ingin menutup laporan ini? Mohon berikan kesimpulan.',
                  style: AppStyles.bodyText2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: conclusionController,
                  decoration: AppStyles.standardInputDecoration(
                    labelText: 'Kesimpulan',
                    prefixIcon: Icons.notes,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kesimpulan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Batal', style: TextStyle(color: AppColors.darkGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (conclusionController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kesimpulan tidak boleh kosong.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Tutup Laporan'),
            ),
          ],
        );
      },
    );
    if (result == true && widget.report.id != null) {
      final reportProvider = Provider.of<ReportProvider>(
        context,
        listen: false,
      );
      try {
        await reportProvider.updateReporttutup(
          widget.report.id,
          conclusionController.text,
        );

        if (reportProvider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil ditutup!')),
          );
          _fetchReportDetails(); // Refresh detail laporan
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menutup laporan: ${reportProvider.errorMessage}',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }
    conclusionController.dispose();
  }

  Future<void> _fetchReportDetails() async {
    setState(() {
      _isLoadingNotes = true;
      _notesErrorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final reportNoteProvider = Provider.of<ReportNoteProvider>(
      context,
      listen: false,
    );

    await reportProvider.getReportById(widget.report.id);
    await reportNoteProvider.fetchReportNotes(widget.report.id);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _notesErrorMessage = 'Authentication token missing.';
        _isLoadingNotes = false;
      });
      return;
    }

    final url = Uri.parse('${AppConstants.apiUrl}/reports/${widget.report.id}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      // print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentReport = Report.fromJson(data);
          // print(_currentReport);
        });
      } else {
        _notesErrorMessage =
            'Gagal memuat detail laporan: ${response.statusCode}';
        debugPrint('Failed to load report details: ${response.body}');
      }
    } catch (e) {
      _notesErrorMessage = 'Terjadi kesalahan jaringan: $e';
      debugPrint('Error fetching report details: $e');
    } finally {
      setState(() {
        _isLoadingNotes = false;
      });
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

  // bool canCloseReport =
  //     (currentUserRole == 'admin' || currentUserRole == 'bk') &&
  //     _report!.status != 'selesai';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    // final currentUserRole = authProvider.user?.role;
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Detail Laporan'),

        // Tambahkan tombol edit laporan jika diperlukan
        actions: [
          _currentReport.status != 'selesai'
              ? (authProvider.user?.id == _currentReport.assignedToBk?.id)
                  ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Tutup ',
                    // onPressed: () {},
                    onPressed: _showCloseReportDialog,
                  )
                  : Text('')
              : _buildTag(
                'Status: ${StringExtension(_currentReport.status).toCapitalized()}',
                AppColors.white,
              ),
          // Text('ini role nya ${_currentReport.assignedToBk?.name}'),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Laporan',
            onPressed: () async {
              // Navigasi ke EditReportScreen, passing objek laporan saat ini
              final bool? result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          EditReportScreen(reportId: _currentReport.id),
                ),
              );
              // Jika ada perubahan, refresh data di halaman detail
              if (result == true) {
                _fetchReportDetails();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportDetails,
        color: AppColors.primaryBlue,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReportSummaryCard(_currentReport),
              const SizedBox(height: 16),
              _buildReportDetailsCard(_currentReport, currentUser),
              const SizedBox(height: 16),
              Text(
                'Catatan Laporan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingNotes
                  ? const Center(child: CircularProgressIndicator())
                  : _notesErrorMessage != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _notesErrorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                  : (_currentReport.notes == null ||
                          _currentReport.notes!.isEmpty
                      ? Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Icon(
                              Icons.notes,
                              size: 60,
                              color: AppColors.darkGrey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada catatan untuk laporan ini.',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap:
                            true, // Penting untuk ListView di dalam SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Non-scrollable inside parent scroll
                        itemCount: _currentReport.notes!.length,
                        itemBuilder: (context, index) {
                          final note = _currentReport.notes![index];
                          return _buildReportNoteCard(note);
                        },
                      )),
            ],
          ),
        ),
      ),

      // Floating Action Button untuk menambah catatan
      floatingActionButton:
          (_currentReport.status != 'selesai' &&
                  currentUser!.id == _currentReport.assignedToBkId)
              ? FloatingActionButton(
                onPressed: () async {
                  final bool? result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddReportNoteScreen(reportId: widget.report.id),
                    ),
                  );
                  if (result == true) {
                    // print('cek tampil');
                    // Jika catatan berhasil ditambahkan, refresh data
                    _fetchReportDetails();
                  }
                },
                child: const Icon(Icons.add_comment),
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              )
              : null,
    );
  }

  Widget _buildReportSummaryCard(Report report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, color: AppColors.darkGrey, size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    'Siswa: ${report.student?.name ?? 'N/A'} (${report.student?.studentClass?.name ?? 'N/A'})',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.black.withOpacity(0.8),
                    ),
                    // style: AppStyles.bodyText2,
                    // <--- TAMBAHKAN INI
                    overflow: TextOverflow.clip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _buildTag('Tipe: ${report.reportType}', AppColors.lightBlue),
                _buildTag(
                  'Status: ${StringExtension(report.status).toCapitalized()}',
                  report.status == 'baru'
                      ? AppColors.errorRed
                      : (report.status == 'ditangani'
                          ? AppColors.secondaryBlue
                          : AppColors.successGreen),
                ),
                _buildTag(
                  'Urgency: ${_formatUrgency(report.urgencyLevel)}',
                  _getUrgencyColor(report.urgencyLevel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportDetailsCard(Report report, User? currentUser) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deskripsi Laporan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.black.withOpacity(0.9),
              ),
            ),
            const Divider(
              height: 30,
              thickness: 1,
              color: AppColors.mediumGrey,
            ),
            _buildInfoRow(
              'Dibuat Oleh',
              report.reported_by?.name ?? 'N/A',
              Icons.person_outline,
            ),
            // shield_person_outline
            _buildInfoRow(
              'Ditugaskan ke BK / Walas',
              report.assignedToBk?.name ?? 'N/A',
              Icons.person_2_outlined,
            ),

            _buildInfoRow(
              'Kesimpulan BK',
              report.conclusion ?? 'Belum ada',
              Icons.check_circle_outline,
            ),

            if (report.status != 'selesai' &&
                report.assignedToBk !=
                    null && // Pastikan ada user yang ditugaskan
                report.assignedToBk!.role ==
                    'wali_kelas' && // Hanya wali kelas yang bisa meneruskan
                // && currentUser != null && // Pastikan ada user yang login
                currentUser?.role ==
                    'wali_kelas' && // Pastikan user yang login adalah wali kelas
                currentUser?.id ==
                    report
                        .assignedToBk!
                        .id // Pastikan wali kelas yang login adalah yang ditugaskan
                        )
              // if (report.assignedToBk!.role == 'wali_kelas' ||
              //     report.assignedToBk!.role == 'bk')
              //   if (report.status != 'selesai' &&
              //       report.assignedToBk!.role != 'bk')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ElevatedButton.icon(
                  // onPressed: () {},
                  onPressed: () => _showForwardConfirmationDialog(context),
                  icon: const Icon(Icons.send, color: AppColors.white),
                  label: Text(
                    'Teruskan ke BK',
                    style: AppStyles.buttonTextStyle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors
                            .warningOrange, // Warna kuning untuk diteruskan
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(
                      50,
                    ), // Buat tombol lebih lebar
                  ),
                ),
              ),
            // _buildInfoRow(
            //   'Diselesaikan Pada',
            //   report.resolvedAt != null
            //       ? DateFormat('dd MMMM yyyy, HH:mm').format(report.resolvedAt!)
            //       : 'Belum selesai',
            //   Icons.event_available,
            // ),
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
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportNoteCard(ReportNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  StringExtension(
                    note.noteType.replaceAll('_', ' '),
                  ).toCapitalized(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryBlue,
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM yy, HH:mm',
                  ).format(note.createdAt ?? DateTime.now()),
                  style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 0.5),
            Text(
              note.noteDetail,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.black.withOpacity(0.9),
              ),
            ),
            if (note.followUpPlan != null && note.followUpPlan!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Rencana Tindak Lanjut: ${note.followUpPlan}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),

            const Divider(height: 16, thickness: 0.5),

            // if (note.photo_path != null && note.photo_path!.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 12.0),
            //     child: Center(
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(8),
            //         child: Image.network(
            //           '${AppConstants.apiUrl.replaceAll('/api', '')}/storage/${note.photo_path}',
            //           // '${AppConstants.apiUrl.replaceAll('/api', '')}/storage/public/report_notes_photos/${note.photo_path}', // Sesuaikan URL path
            //           fit: BoxFit.cover,
            //           width: double.infinity,
            //           height: 150,
            //           errorBuilder:
            //               (context, error, stackTrace) => Container(
            //                 height: 150,
            //                 color: AppColors.lightGrey,
            //                 child: Center(
            //                   child: Icon(
            //                     Icons.broken_image,
            //                     color: AppColors.darkGrey,
            //                   ),
            //                 ),
            //               ),
            //         ),
            //       ),
            //     ),
            //   ),
            // const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Oleh: ${note.bk_user?.name ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
              ),
            ),
          ],
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
