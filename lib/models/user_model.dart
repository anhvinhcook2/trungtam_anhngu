class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // admin, teacher, student
  final String? studentCode; // HV-YYYY-NNNNN
  final String? tuitionStatus; // Đã đóng | Chưa đóng

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.studentCode,
    this.tuitionStatus = 'Chưa đóng',
  });

  // Chuyển dữ liệu từ Firestore về Model với xử lý null-safe
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      studentCode: data['studentCode'] ?? data['student_code'],
      tuitionStatus: data['tuitionStatus'] ?? data['tuition_status'] ?? 'Chưa đóng',
    );
  }

  // Chuyển Model thành Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'studentCode': studentCode,
      'tuitionStatus': tuitionStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Phương thức kiểm tra role nhanh
  bool isStudent() => role == 'student';
  bool isTeacher() => role == 'teacher';
  bool isAdmin() => role == 'admin';
}
