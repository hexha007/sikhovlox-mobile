// lib/models/student.dart
import 'package:nebeng_app/models/student_class.dart';

class Student {
  final int id;
  final int classId;
  final String nis;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final String? parentPhone;
  final String? address;
  final StudentClass? studentClass; // Relasi

  final int? reportsCount; // Jumlah laporan (BARU)
  final DateTime? latestReportDate; // Tanggal laporan terakhir (BARU)

  Student({
    required this.id,
    required this.classId,
    required this.nis,
    required this.name,
    required this.gender,
    this.birthDate,
    this.parentPhone,
    this.address,
    this.studentClass,

    this.reportsCount, // Tambahkan di constructor
    this.latestReportDate, // Tambahkan di constructor
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      classId: json['class_id'],
      nis: json['nis'],
      name: json['name'],
      gender: json['gender'],
      birthDate:
          json['birth_date'] != null
              ? DateTime.parse(json['birth_date'])
              : null,
      parentPhone: json['parent_phone'],
      address: json['address'],
      studentClass:
          json['student_class'] != null
              ? StudentClass.fromJson(json['student_class'])
              : null,
      reportsCount: json['reports_count'], // Parsing data baru
      latestReportDate:
          json['latest_report_date'] != null
              ? DateTime.parse(json['latest_report_date'])
              : null, // Parsing data baru
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'nis': nis,
      'name': name,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String(),
      'parent_phone': parentPhone,
      'address': address,
      'student_class': studentClass?.toJson(),
      'reports_count': reportsCount,
      'latest_report_date': latestReportDate?.toIso8601String(),
    };
  }
}
