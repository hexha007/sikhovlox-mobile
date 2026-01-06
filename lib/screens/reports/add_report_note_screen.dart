// lib/screens/add_report_note_screen.dart

import 'package:flutter/material.dart';
import 'package:nebeng_app/models/ReportNote.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nebeng_app/providers/report_note_provider.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'package:nebeng_app/utils/app_styles.dart';

class AddReportNoteScreen extends StatefulWidget {
  final int reportId;

  const AddReportNoteScreen({super.key, required this.reportId});

  @override
  State<AddReportNoteScreen> createState() => _AddReportNoteScreenState();
}

class _AddReportNoteScreenState extends State<AddReportNoteScreen> {
  final TextEditingController _noteDetailController =
      TextEditingController(); // Ganti nama
  final TextEditingController _followUpPlanController =
      TextEditingController(); // BARU
  File? _pickedPhoto; // Ganti nama
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String? _selectedNoteType; // BARU: untuk dropdown note_type
  final List<String> _noteTypeOptions = [
    'Observasi',
    'Tindakan_yang_Diambil',
    'Catatan_Rapat',
    'Komunikasi_dengan_Orang_Tua',
    'Wawancara_Siswa',
    'lainnya',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _pickedPhoto = File(pickedFile.path);
      } else {
        debugPrint('No photo selected.');
      }
    });
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitNote() async {
    if (_selectedNoteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipe catatan harus dipilih.')),
      );
      return;
    }

    if (_noteDetailController.text.trim().isEmpty) {
      // Validasi note_detail
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detail catatan tidak boleh kosong.')),
      );
      return;
    }

    final reportNoteProvider = Provider.of<ReportNoteProvider>(
      context,
      listen: false,
    );

    bool success = false;
    await reportNoteProvider
        .addReportNote2(
          widget.reportId,
          _selectedNoteType!,
          _noteDetailController.text.trim(),
          _followUpPlanController.text.trim().isNotEmpty
              ? _followUpPlanController.text.trim()
              : null, // follow_up_plan
          _pickedPhoto, // photo
        )
        .then((newNote) {
          if (newNote != null) {
            success = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catatan berhasil ditambahkan!')),
            );
          }
        });

    if (success) {
      Navigator.pop(
        context,
        true,
      ); // Kembali dan beritahu ReportDetailScreen untuk refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reportNoteProvider.errorMessage ?? 'Gagal menambahkan catatan.',
          ),
        ),
      );
    }
  }
  // Future<void> _submitNote() async {
  //   if (_selectedNoteType == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Tipe catatan harus dipilih.')),
  //     );
  //     return;
  //   }

  //   if (_noteDetailController.text.trim().isEmpty) {
  //     // Validasi note_detail
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Detail catatan tidak boleh kosong.')),
  //     );
  //     return;
  //   }

  //   final reportNoteProvider = Provider.of<ReportNoteProvider>(
  //     context,
  //     listen: false,
  //   );

  //   final newNote = ReportNote(
  //     reportId: widget.reportId,
  //     noteType: _selectedNoteType!,
  //     noteDetail: _noteDetailController.text,
  //     followUpPlan:
  //         _followUpPlanController.text.isEmpty
  //             ? null
  //             : _followUpPlanController.text,

  //     // photo akan dihandle terpisah
  //   );

  //   try {

  //     await reportNoteProvider.addReportNote(
  //       widget.reportId,
  //       newNote,
  //       '',
  //       photoFile: _pickedPhoto,
  //     );

  //     if (reportNoteProvider.errorMessage == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Catatan laporan berhasil ditambahkan!'),
  //         ),
  //       );
  //       Navigator.of(
  //         context,
  //       ).pop(true); // Kembali ke layar sebelumnya dengan indikasi sukses
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Gagal menambahkan catatan: ${reportNoteProvider.errorMessage}',
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Catatan Laporan')),
      body: Consumer<ReportNoteProvider>(
        builder: (context, reportNoteProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ID Laporan: ${widget.reportId}',
                  style: AppStyles.heading3.copyWith(color: AppColors.darkGrey),
                ),
                const SizedBox(height: 16),
                // Dropdown untuk Tipe Catatan
                DropdownButtonFormField<String>(
                  value: _selectedNoteType,
                  decoration: InputDecoration(
                    labelText: 'Tipe Catatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  hint: const Text('Pilih Tipe Catatan'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedNoteType = newValue;
                    });
                  },
                  items:
                      _noteTypeOptions.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.replaceAll('_', ' '),
                          ), // Tampilan lebih rapi
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                // Text Field untuk Detail Catatan
                TextField(
                  controller: _noteDetailController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Detail Catatan',
                    hintText: 'Tuliskan detail catatan di sini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Text Field untuk Follow Up Plan
                TextField(
                  controller: _followUpPlanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Rencana Tindak Lanjut (Opsional)',
                    hintText: 'Tuliskan rencana tindak lanjut di sini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Tampilan Foto yang Dipilih
                _pickedPhoto != null
                    ? Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _pickedPhoto!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
                // Tombol Ambil Foto
                ElevatedButton.icon(
                  onPressed: () => _showImageSourceActionSheet(context),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _pickedPhoto != null ? 'Ubah Foto' : 'Ambil/Pilih Foto',
                    style: AppStyles.buttonTextStyle,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_pickedPhoto != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pickedPhoto = null; // Hapus foto
                        });
                      },
                      icon: const Icon(
                        Icons.delete_forever,
                        color: AppColors.errorRed,
                      ),
                      label: Text(
                        'Hapus Foto',
                        style: AppStyles.buttonTextStyle.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                // Tombol Simpan
                ElevatedButton(
                  onPressed: reportNoteProvider.isLoading ? null : _submitNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      reportNoteProvider.isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          )
                          : Text(
                            'Simpan Catatan',
                            style: AppStyles.buttonTextStyle.copyWith(
                              fontSize: 18,
                            ),
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
