import 'package:nebeng_app/models/user.dart';

class StudentClass {
  final int id;
  final String name;
  // final int level;
  // final String major;
  final int? waliKelasId;
  final User? waliKelas; // Relasi

  StudentClass({
    required this.id,
    required this.name,
    // required this.level,
    // required this.major,
    this.waliKelasId,
    this.waliKelas,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    return StudentClass(
      id: json['id'],
      name: json['name'],
      // level: json['level'],
      // major: json['major'],
      waliKelasId: json['wali_kelas_id'],
      waliKelas:
          json['wali_kelas'] != null ? User.fromJson(json['wali_kelas']) : null,
    );
  }

  // Penting: Implementasikan == dan hashCode untuk perbandingan objek
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentClass && other.id == id; // Bandingkan berdasarkan ID
  }

  @override
  int get hashCode => id.hashCode; // Gunakan ID untuk hashCode

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // 'level': level,
      // 'major': major,
      'wali_kelas_id': waliKelasId,
      'wali_kelas': waliKelas?.toJson(),
    };
  }
}
