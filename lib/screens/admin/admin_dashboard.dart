import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'admin_teacher_management.dart';
import 'admin_student_management.dart';
import 'admin_class_management.dart';
import 'admin_schedule_management.dart';
import 'admin_tuition_management.dart';
import 'admin_chat_list_screen.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
    }
  }

  Widget _buildBentoCard(BuildContext context, String title, IconData icon, Color color, Stream<QuerySnapshot> stream, Widget screen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                radius: 24,
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Text("$count", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color));
                },
              ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      drawer: const AdminDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("QUẢN TRỊ VIÊN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)),
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F46E5), Color(0xFF312E81)]),
                    ),
                  ),
                  Positioned(top: -20, right: -20, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withAlpha(20))),
                  Positioned(bottom: 20, left: 40, child: CircleAvatar(radius: 10, backgroundColor: Colors.white.withAlpha(40))),
                ],
              ),
            ),
            actions: [IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white))],
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
                _buildBentoCard(context, "Học Viên", Icons.groups_rounded, const Color(0xFF3B82F6), db.collection('users').where('role', isEqualTo: 'student').snapshots(), const AdminStudentManagement()),
                _buildBentoCard(context, "Lớp Học", Icons.class_rounded, const Color(0xFF10B981), db.collection('classes').snapshots(), const AdminClassManagement()),
                _buildBentoCard(context, "Thời khóa biểu", Icons.calendar_today_rounded, const Color(0xFF8B5CF6), db.collection('schedules').snapshots(), const AdminScheduleManagement()),
                _buildBentoCard(context, "Học phí", Icons.payments_rounded, const Color(0xFFF59E0B), db.collection('tuition').snapshots(), const AdminTuitionManagement()),
                _buildBentoCard(context, "Chat Phụ huynh", Icons.chat_rounded, const Color(0xFFEF4444), db.collection('chats').snapshots(), const AdminChatListScreen()),
              ]),
            ),
          )
        ],
      ),
    );
  }
}
