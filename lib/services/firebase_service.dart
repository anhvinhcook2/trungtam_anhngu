import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Khởi tạo Firebase chính
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2. Tạo instance thứ 2 để Admin tạo User mà không bị Logout instance chính
  Future<FirebaseApp> createSecondaryInstance() async {
    String name = "SecondaryApp_${DateTime.now().millisecondsSinceEpoch}";
    return await Firebase.initializeApp(
      name: name,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 3. Sinh mã số học viên: HV-2024-XXXXX (8 ký tự millis)
  String generateStudentCode() {
    String year = DateTime.now().year.toString();
    String millis = DateTime.now().millisecondsSinceEpoch.toString();
    // Lấy 8 ký tự cuối của timestamp để đảm bảo độ dài và tính duy nhất tương đối
    String uniquePart = millis.substring(millis.length - 8);
    return "HV-$year-$uniquePart";
  }

  // 4. Xóa tài khoản (Auth + Firestore)
  // Lưu ý: Cần re-authenticate nếu user đã login lâu
  Future<void> deleteUserAccount(String uid, String password) async {
    User? user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      // Re-authenticate trước khi xóa Auth
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Xóa Firestore doc trước
      await _db.collection('users').doc(uid).delete();
      
      // Xóa Auth account
      await user.delete();
    } else {
      // Nếu Admin xóa hộ (chỉ xóa được Firestore trên Spark Plan client-side)
      await _db.collection('users').doc(uid).delete();
    }
  }

  // 5. Lấy dữ liệu user theo UID (Stream)
  Stream<UserModel> getUserById(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      throw Exception("User not found");
    });
  }
}
