import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Khai báo màu sắc theo UI/UX Concept
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green

  // Widget Loading tuân thủ concept hình khối (Card bo góc, soft shadow)
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Bo góc 16px
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // Bóng đổ mờ
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang đồng bộ dữ liệu...',
              style: TextStyle(
                fontFamily: 'Nunito', // Hoặc Poppins/Quicksand tùy bạn cấu hình trong pubspec
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
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
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String role = userSnapshot.data!.get('role') ?? 'student';

                // Điều hướng dựa trên logic gốc
                if (role == 'admin') return const AdminDashboard();
                if (role == 'teacher') return const TeacherDashboard();
                return const StudentDashboard();
              }

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