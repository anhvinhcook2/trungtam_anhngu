import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/admin/admin_chat_list_screen.dart';

import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_teacher_management.dart';
import '../screens/admin/admin_student_management.dart';
import '../screens/admin/admin_class_management.dart';
import '../screens/admin/admin_schedule_management.dart';
import '../screens/admin/admin_tuition_management.dart';


class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  final Color _primaryColor = const Color(0xFF004D40);
  final Color _secondaryColor = const Color(0xFF00695C);
  final Color _bgColor = const Color(0xFFF8F9FA);
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
          style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700], fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER CAO CẤP (ORGANIC SHAPE) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(48), // Độ cong sâu tạo cảm giác mềm mại (Organic)
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.shield_rounded, size: 32, color: Color(0xFF004D40)),
                      ),
                    ),
                    const Spacer(),
                    // Nút đóng Drawer nhỏ nhắn góc phải
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Admin System",
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    FirebaseAuth.instance.currentUser?.email ?? "admin@trungtam.com",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // --- DANH SÁCH MENU ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(context, "Bảng điều khiển", Icons.dashboard_rounded, const AdminDashboard()),
                _buildMenuItem(context, "Quản lý Giáo viên", Icons.person_search_rounded, const AdminTeacherManagement()),
                _buildMenuItem(context, "Quản lý Học viên", Icons.groups_rounded, const AdminStudentManagement()),
                _buildMenuItem(context, "Quản lý Lớp học", Icons.class_rounded, const AdminClassManagement()),
                _buildMenuItem(context, "Quản lý Lịch học", Icons.calendar_today_rounded, const AdminScheduleManagement()),
                _buildMenuItem(context, "Quản lý Học phí", Icons.payments_rounded, const AdminTuitionManagement()),
                _buildMenuItem(context, "Chat", Icons.chat_rounded, const AdminChatListScreen()),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                
                // _buildMenuItem(context, "Hộp thư hỗ trợ", Icons.inbox_rounded, const AdminSupportInbox()), // Bỏ comment nếu dùng
              ],
            ),
          ),
          
          // --- NÚT ĐĂNG XUẤT ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: InkWell(
              onTap: () => _logout(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "Đăng xuất", 
                      style: TextStyle(
                        fontFamily: _fontFamily, 
                        color: Colors.red.shade600, 
                        fontWeight: FontWeight.w800, 
                        fontSize: 15
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Hàm build từng item của menu chuẩn phong cách Organic
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px
        hoverColor: _bgColor,
        splashColor: _primaryColor.withValues(alpha: 0.1),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(12),
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
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20), // Thêm mũi tên điều hướng
        onTap: () {
          Navigator.pop(context); // Đóng drawer
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
      ),
    );
  }
}
