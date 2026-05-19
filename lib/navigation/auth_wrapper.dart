import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Nếu đã đăng nhập thành công
        if (authSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // Đọc thông tin vai trò từ Firestore [cite: 9]
                String role = userSnapshot.data!.get('role') ?? 'student';

                // Điều hướng dựa trên quyền hạn [cite: 21, 295]
                if (role == 'admin') return const AdminDashboard();
                if (role == 'teacher') return const TeacherDashboard();
                return const StudentDashboard();
              }

              //return const Scaffold(body: Center(child: Text("Lỗi: Không tìm thấy dữ liệu người dùng")));
              return const LoginScreen();
            },
          );
        }

        // Nếu chưa đăng nhập, trả về màn hình Login
        return const LoginScreen();
      },
    );
  }
}