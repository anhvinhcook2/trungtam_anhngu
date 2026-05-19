import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trungtam_anhngu/model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Đăng ký tài khoản mới
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // 1. Tạo user trên Firebase Auth
      UserCredential res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = res.user;

      if (user != null) {
        // 2. Tạo thông tin chi tiết trên Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
          // Nếu là học viên, có thể tạo mã số ngẫu nhiên hoặc để admin cấp sau
          studentCode: role == 'student' ? "ST${user.uid.substring(0, 5).toUpperCase()}" : null,
        );

        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        return null; // Thành công
      }
    } catch (e) {
      return e.toString();
    }
    return "Lỗi không xác định";
  }

  // Đăng nhập
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }
}