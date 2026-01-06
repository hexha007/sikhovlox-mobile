// lib/models/report.dart
import 'package:nebeng_app/models/ReportNote.dart';
import 'package:nebeng_app/models/student.dart';
import 'package:nebeng_app/models/user.dart';

class Report {
  final int id;
  final int studentId;
  final String title;
  final String description;
  final String reportType;
  final String urgencyLevel;
  final String status;
  final int created_by_id;
  final int assignedToBkId;
  // final String? actionsTakenByReporter;
  // final String? expectationFromBk;
  final String? conclusion;
  // final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Student? student; // Relasi
  final User? reported_by; // Relasi
  final User? assignedToBk; // Relasi
  final List<ReportNote>? notes; // Relasi
  // Data relasi student
  // final User? creator; // Data relasi user (creator)
  final int? reportNotesCount; // BARU: Jumlah notes untuk laporan ini

  Report({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.reportType,
    required this.urgencyLevel,
    required this.status,
    required this.created_by_id,
    required this.assignedToBkId,
    // this.actionsTakenByReporter,
    // this.expectationFromBk,
    this.conclusion,
    // this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.reported_by,
    this.assignedToBk,
    this.notes,
    this.reportNotesCount, // Tambahkan di constructor
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      studentId: json['student_id'],
      title: json['title'],
      description: json['description'],
      reportType: json['report_type'],
      urgencyLevel: json['urgency_level'],
      status: json['status'],
      created_by_id: json['created_by_id'],
      assignedToBkId: json['assigned_to_bk_id'],
      // actionsTakenByReporter: json['actions_taken_by_reporter'],
      // expectationFromBk: json['expectation_from_bk'],
      conclusion: json['conclusion'],
      // resolvedAt:
      //     json['resolved_at'] != null
      //         ? DateTime.parse(json['resolved_at'])
      //         : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      student:
          json['student'] != null ? Student.fromJson(json['student']) : null,
      reported_by:
          json['reported_by'] != null
              ? User.fromJson(json['reported_by'])
              : null,
      assignedToBk:
          json['assigned_to_bk'] != null
              ? User.fromJson(json['assigned_to_bk'])
              : null,
      notes:
          json['notes'] != null
              ? (json['notes'] as List)
                  .map((e) => ReportNote.fromJson(e))
                  .toList()
              : null,
      reportNotesCount: json['report_notes_count'], // Parsing data baru
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'description': description,
      'report_type': reportType,
      'urgency_level': urgencyLevel,
      'status': status,
      'created_by_id': created_by_id,
      'assigned_to_bk_id': assignedToBkId,
      // 'actions_taken_by_reporter': actionsTakenByReporter,
      // 'expectation_from_bk': expectationFromBk,
      'conclusion': conclusion,
      // 'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'student': student?.toJson(),
      'reported_by': reported_by?.toJson(),
      'assigned_to_bk': assignedToBk?.toJson(),
      'notes': notes?.map((e) => e.toJson()).toList(),
      'report_notes_count': reportNotesCount,
    };
  }

  Report copyWith({
    int? id,
    int? studentId,
    String? title,
    String? description,
    String? reportType,
    String? urgencyLevel,
    String? actionsTakenByReporter,
    String? expectationFromBk,
    int? assignedToBkId,
    String? status,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      reportType: reportType ?? this.reportType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,

      assignedToBkId: assignedToBkId ?? this.assignedToBkId,
      status: status ?? this.status,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      created_by_id: created_by_id ?? this.created_by_id,
    );
  }
}
