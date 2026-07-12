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

  final Color _primaryColor = const Color(0xFF004D40); // Teal-ish Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA);
  final String _fontFamily = 'Nunito';

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Xác nhận", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc chắn muốn đăng xuất?", style: TextStyle(fontFamily: _fontFamily)),
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
      }
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Widget screen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withOpacity(0.1), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: _primaryColor, size: 28),
                ),
                const Spacer(),
                Text(value, style: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w900, color: _primaryColor)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime endOfWeek = startOfDay.add(const Duration(days: 7));

    return Scaffold(
      backgroundColor: _bgColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Tổng quan Quản trị", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        backgroundColor: _primaryColor,
        actions: [
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout, color: Colors.white)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, classSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
                  builder: (context, studentSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
                      builder: (context, teacherSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('tuition').where('status', isEqualTo: 'pending').snapshots(),
                          builder: (context, tuitionSnap) {
                            
                            final totalClasses = classSnap.hasData ? classSnap.data!.docs.length : 0;
                            final totalStudents = studentSnap.hasData ? studentSnap.data!.docs.length : 0;
                            final totalTeachers = teacherSnap.hasData ? teacherSnap.data!.docs.length : 0;
                            final pendingDebts = tuitionSnap.hasData ? tuitionSnap.data!.docs.length : 0;

                            return Column(
                              children: [
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.0,
                                  children: [
                                    _buildStatCard(context, "Số lượng lớp", "$totalClasses", Icons.class_rounded, const AdminClassManagement()),
                                    _buildStatCard(context, "Học viên", "$totalStudents", Icons.groups_rounded, const AdminStudentManagement()),
                                    _buildStatCard(context, "Giảng viên", "$totalTeachers", Icons.badge_rounded, const AdminTeacherManagement()),
                                    _buildStatCard(
                                      context, 
                                      "Học phí", 
                                      pendingDebts == 0 ? "Đã đóng" : "Còn $pendingDebts nợ", 
                                      Icons.payments_rounded, 
                                      const AdminTuitionManagement(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildWeeklyScheduleChart(startOfDay, endOfWeek),
                              ],
                            );
                          }
                        );
                      }
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleChart(DateTime start, DateTime end) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Biểu đồ ca dạy tuần này", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 16, color: _primaryColor)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schedules')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                .where('date', isLessThan: Timestamp.fromDate(end))
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              var schedules = snapshot.data!.docs;
              List<int> counts = List.generate(7, (index) => schedules.where((s) => s['dayOfWeek'] == (index + 1)).length);
              
              // Sử dụng một ngưỡng cố định (ví dụ 5 ca/ngày) để scale chiều cao, 
              // đảm bảo 1 ca luôn thấp hơn 2 ca.
              const int maxCapacity = 5; 

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  return Column(
                    children: [
                      Container(
                        width: 30,
                        height: 120,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: FractionallySizedBox(
                          heightFactor: (counts[i] / maxCapacity).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(i == 6 ? "CN" : "T${i + 2}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
