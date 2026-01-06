// lib/models/user.dart
import 'package:nebeng_app/models/student_class.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? classId;
  final String? class_name;
  final StudentClass? studentClass; // Relasi

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.studentClass,
    this.class_name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      classId: json['class_id'],
      class_name: json['class_name'],
      studentClass:
          json['student_class'] != null
              ? StudentClass.fromJson(json['student_class'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'class_id': classId,
      'class_name': class_name,
      'student_class': studentClass?.toJson(),
    };
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Jika objeknya sama persis
    return other is User &&
        other.id == id; // Jika itu User lain dan ID-nya sama
  }

  @override
  int get hashCode => id.hashCode; // Hash code berdasarkan ID
}

// lib/models/student_class.dart


// Lanjutkan untuk Student, Report, ReportNote dengan cara yang sama



