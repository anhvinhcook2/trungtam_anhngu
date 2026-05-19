class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // admin, teacher, student
  final String? studentCode;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.studentCode,
  });

  // Chuyển dữ liệu từ Firestore về Model
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      studentCode: data['student_code'],
    );
  }

  // Chuyển Model thành Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'student_code': studentCode,
      'createdAt': DateTime.now(),
    };
  }
}