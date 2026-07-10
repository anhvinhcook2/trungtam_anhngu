import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // admin, teacher, student
  final String? studentCode; // Giữ lại property này cho Flutter Code
  final String? tuitionStatus; // Giữ lại property này cho Flutter Code

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.studentCode,
    this.tuitionStatus = 'Chưa đóng',
  });

  // Chuyển dữ liệu từ Firestore về Model với chuẩn snake_case từ DB
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      studentCode: data['student_code'] ?? data['studentCode'],
      tuitionStatus: data['tuition_status'] ?? data['tuitionStatus'] ?? 'Chưa đóng',
    );
  }

  // Chuyển Model thành Map để lưu lên Firestore theo chuẩn snake_case
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'student_code': studentCode,
      'tuition_status': tuitionStatus,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // Phương thức kiểm tra role nhanh
  bool isStudent() => role == 'student';
  bool isTeacher() => role == 'teacher';
  bool isAdmin() => role == 'admin';
}
