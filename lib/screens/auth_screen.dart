import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- BẢNG MÀU CHUẨN CONCEPT ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt cho CTA
  final String _fontFamily = 'Nunito'; // Font chữ bo tròn, thân thiện

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập Email và Mật khẩu"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential res = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        DocumentSnapshot userDoc = await _db.collection('users').doc(res.user!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final String role = (userData?['role'] as String?) ?? 'student';
          
          if (!mounted) return;
          
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
          } else if (role == 'teacher') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
          } else {
            // Học viên đăng nhập
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
          }
        } else {
          // Fallback nếu thiếu doc
          await _auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Dữ liệu tài khoản bị lỗi. Vui lòng liên hệ Admin."),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Đăng nhập thất bại.";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        msg = "Tài khoản không tồn tại.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = "Sai mật khẩu.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi hệ thống: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor, // Chuyển sang Light Grey thay vì gradient
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), // Bóng đổ mờ
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.school_rounded, size: 60, color: _primaryColor);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  "English For Life",
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor, // Đổi sang Deep Jungle Green
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "HỆ THỐNG QUẢN LÝ ĐÀO TẠO",
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),

                // Card Container (Form đăng nhập) bo góc 16px
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16), // Bo góc 16px theo chuẩn
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), // Soft shadow
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chào mừng quay trở lại!",
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Vui lòng đăng nhập tài khoản của bạn.",
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Email đăng nhập",
                          labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.email_outlined, color: _primaryColor, size: 22),
                          filled: true,
                          fillColor: _bgColor, // Trùng với nền xám nhạt để tạo chiều sâu nhẹ
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Bo góc 12px cho input
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Mật khẩu",
                          labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 22),
                          filled: true,
                          fillColor: _bgColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nút Đăng Nhập CTA - Sử dụng màu Điểm nhấn (Vàng nghệ / Cam)
                      SizedBox(
                        width: double.infinity,
                        height: 52, // Độ cao nút tiêu chuẩn
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor, // Màu Vàng/Cam tạo điểm nhấn mạnh
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Bo góc 12px
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                "ĐĂNG NHẬP",
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
