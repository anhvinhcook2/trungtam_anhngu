import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_teacher_management.dart';
import '../screens/admin/admin_student_management.dart';
import '../screens/admin/admin_class_management.dart';
import '../screens/admin/admin_schedule_management.dart';
import '../screens/admin/admin_tuition_management.dart';
import '../screens/admin/admin_support_inbox.dart'; // Tuỳ bạn có thêm vào menu không

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final String _fontFamily = 'Nunito';

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bo góc chuẩn 24px
        title: Text(
          "Xác nhận", 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?",
          style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Đăng xuất", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Custom Header mang hơi hướng Organic (Bo tròn góc dưới)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(40), // Tạo đường cong tự nhiên
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings_rounded, size: 36, color: Color(0xFF004D40)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Admin System",
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "admin@trungtam.com",
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Danh sách menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, "Bảng điều khiển", Icons.dashboard_rounded, const AdminDashboard()),
                _buildMenuItem(context, "Quản lý Giáo viên", Icons.person_search_rounded, const AdminTeacherManagement()),
                _buildMenuItem(context, "Quản lý Học viên", Icons.groups_rounded, const AdminStudentManagement()),
                _buildMenuItem(context, "Quản lý Lớp học", Icons.class_rounded, const AdminClassManagement()),
                _buildMenuItem(context, "Quản lý TKB", Icons.calendar_today_rounded, const AdminScheduleManagement()),
                _buildMenuItem(context, "Quản lý Học phí", Icons.payments_rounded, const AdminTuitionManagement()),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          
          // Nút Đăng xuất ở dưới cùng
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px khi hover/nhấn
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22),
              ),
              title: Text(
                "Đăng xuất", 
                style: TextStyle(fontFamily: _fontFamily, color: Colors.red.shade600, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onTap: () => _logout(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Hàm build từng item của menu
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px chuẩn concept
        hoverColor: _bgColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontFamily: _fontFamily, 
            fontWeight: FontWeight.w700, 
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Đóng drawer
          // Chuyển trang
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
      ),
    );
  }
}