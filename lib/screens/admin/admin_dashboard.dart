import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth_screen.dart';
import 'admin_teacher_management.dart';
import 'admin_student_management.dart';
import 'admin_class_management.dart';
import 'admin_schedule_management.dart';
import 'admin_tuition_management.dart';
import 'admin_chat_list_screen.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final String _fontFamily = 'Nunito';

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold))
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

  Widget _buildBentoCard(BuildContext context, String title, IconData icon, Color color, Stream<QuerySnapshot> stream, Widget screen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                        "$count",
                        style: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w900, color: color)
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                    title,
                    style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: const AdminDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                "Admin System",
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryColor, const Color(0xFF00695C)], // Deep Jungle Green
                      ),
                    ),
                  ),
                  // Các mảng hình tròn trang trí (Organic Shapes)
                  Positioned(
                      top: -40,
                      right: -40,
                      child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05))
                  ),
                  Positioned(
                      bottom: -20,
                      right: 80,
                      child: CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.08))
                  ),
                  Positioned(
                      bottom: 40,
                      left: -20,
                      child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.05))
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                tooltip: "Đăng xuất",
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                _buildBentoCard(context, "Giáo Viên", Icons.person_search_rounded, const Color(0xFFF59E0B), db.collection('users').where('role', isEqualTo: 'teacher').snapshots(), const AdminTeacherManagement()),
                _buildBentoCard(context, "Học Viên", Icons.groups_rounded, _primaryColor, db.collection('users').where('role', isEqualTo: 'student').snapshots(), const AdminStudentManagement()),
                _buildBentoCard(context, "Lớp Học", Icons.class_rounded, const Color(0xFF10B981), db.collection('classes').snapshots(), const AdminClassManagement()),
                _buildBentoCard(context, "Thời khóa biểu", Icons.calendar_today_rounded, const Color(0xFF0F766E), db.collection('schedules').snapshots(), const AdminScheduleManagement()),
                _buildBentoCard(context, "Học phí", Icons.payments_rounded, const Color(0xFF0ea5e9), db.collection('tuition').snapshots(), const AdminTuitionManagement()),
                _buildBentoCard(context, "Tin nhắn", Icons.chat_rounded, const Color(0xFFF43F5E), db.collection('chats').snapshots(), const AdminChatListScreen()),
              ]),
            ),
          )
        ],
      ),
    );
  }
}