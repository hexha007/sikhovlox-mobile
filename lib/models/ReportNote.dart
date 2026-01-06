import 'package:nebeng_app/models/user.dart';

// lib/models/report_note.dart
class ReportNote {
  final int? id;
  final int reportId;
  final String noteType;
  final String noteDetail;
  final String? followUpPlan;
  final String? photo_path;
  final int? bkUserId;
  // final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? bk_user; // Relasi

  ReportNote({
    this.id,
    required this.reportId,
    required this.noteType,
    required this.noteDetail,
    this.followUpPlan,
    this.photo_path,
    this.bkUserId,
    // required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.bk_user,
  });

  factory ReportNote.fromJson(Map<String, dynamic> json) {
    return ReportNote(
      id:
          json['id']
              as int, // Laravel mengirim id sebagai int, jadi 'as int' aman
      // KUNCI: Konversi report_id dari String ke int.
      // toString() memastikan bahwa apapun tipe awalnya, akan dikonversi ke String
      // sebelum di-parse ke int.
      reportId: int.parse(json['report_id'].toString()),
      noteType: json['note_type'] as String,
      noteDetail: json['note_detail'] as String,
      followUpPlan: json['follow_up_plan'] as String?,
      photo_path: json['photo_path'] as String?,
      bkUserId:
          json['bk_user_id']
              as int, // Laravel mengirim bk_user_id sebagai int, jadi 'as int' aman
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bk_user:
          json['bk_user'] != null
              ? User.fromJson(json['bk_user'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'note_type': noteType,
      'note_detail': noteDetail,
      'follow_up_plan': followUpPlan,
      'photo_path': photo_path,
      'bk_user_id': bkUserId,
      // 'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'bk_user': bk_user?.toJson(),
    };
  }
}
