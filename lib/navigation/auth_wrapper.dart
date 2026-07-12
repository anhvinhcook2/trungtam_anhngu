import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final String _fontFamily = 'Nunito';

  // Widget Loading tinh tế với phong cách Organic Tech
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32), // Bo góc lớn hơn
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang kết nối hệ thống...',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primaryColor.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Trạng thái đang tải từ Firebase Auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Nếu đã đăng nhập thành công
        if (authSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              // Trạng thái đang tải dữ liệu người dùng từ Firestore
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasError) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String role = (userData?['role'] as String?) ?? 'student';

                // Điều hướng phân quyền
                if (role == 'admin') return const AdminDashboard();
                if (role == 'teacher') return const TeacherDashboard();
                return const StudentDashboard();
              }

              // Trường hợp người dùng tồn tại trong Auth nhưng không có trong Firestore
              return const AuthScreen();
            },
          );
        }

        // Nếu chưa đăng nhập, trả về màn hình Auth
        return const AuthScreen();
      },
    );
  }
}