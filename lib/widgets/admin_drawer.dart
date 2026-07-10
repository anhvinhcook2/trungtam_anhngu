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
import '../screens/admin/admin_support_inbox.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đăng xuất"),
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
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFFDBF8FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.admin_panel_settings_rounded, size: 40, color: Colors.white),
            ),
            accountName: const Text(
              "Admin System",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              FirebaseAuth.instance.currentUser?.email ?? "admin@trungtam.com",
              style: TextStyle(color: Colors.white.withAlpha(204)), // 0.8 * 255 ≈ 204
            ),
          ),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context); // Đóng drawer
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }
}
