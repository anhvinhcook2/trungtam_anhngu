import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_student_management.dart';
import 'admin_teacher_management.dart';
import 'admin_class_management.dart';
import 'admin_support_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Trị Viên"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Chia 2 cột
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _adminMenuCard(context, "Giáo viên", Icons.person, Colors.orange, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherManagementScreen()));
            }),
            _adminMenuCard(context, "Học viên", Icons.group, Colors.blue, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
            }),
            _adminMenuCard(context, "Lớp học", Icons.school, Colors.green, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassManagementScreen()));
            }),
            _adminMenuCard(context, "Thông báo", Icons.notifications, Colors.red, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSupportScreen()));
            }),
          ],
        ),
      ),
    );
  }


// Cập nhật lại hàm này ở cuối file admin_dashboard.dart
Widget _adminMenuCard(BuildContext context, String title, IconData icon, Color color, {required VoidCallback onTap}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: InkWell(
      onTap: onTap, // Sử dụng tham số onTap ở đây [cite: 329]
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
}