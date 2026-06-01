import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'evaluation_form.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // HÀM: Báo cáo nhanh sau tiết
  Future<void> _submitQuickFeedback(String classId, String className) async {
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Báo Cáo Nhanh\nLớp: $className", style: const TextStyle(color: Colors.amber)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: contentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Nhập tình hình lớp học hôm nay...",
            filled: true,
            fillColor: Colors.amber.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              if (contentController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _db.collection('reports').add({
                  'type': 'feedback',
                  'teacher_id': currentUser!.uid,
                  'class_id': classId,
                  'content': contentController.text.trim(),
                  'status': 'Chưa đọc',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi báo cáo nhanh!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Gửi Báo Cáo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5), // Pastel Amber nhạt
      appBar: AppBar(
        centerTitle: true,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ) : const SizedBox(),
        title: const Text("GIẢNG VIÊN", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.brown, letterSpacing: 1.2)),
        backgroundColor: Colors.amber.shade300,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
            onPressed: () async {
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
                      child: const Text("Đăng xuất")
                    ),
                  ],
                ),
              ) ?? false;
              if (confirm) await _authService.logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lọc danh sách lớp theo teacher_id
        stream: _db.collection('classes').where('teacher_id', isEqualTo: currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Bạn chưa được phân công lớp nào.", style: TextStyle(color: Colors.brown)));

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var c = classes[index].data() as Map<String, dynamic>;
              String classId = classes[index].id;
              List<dynamic> studentIds = c['student_ids'] ?? [];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassStudentsScreen(classId: classId, className: c['name'], studentIds: studentIds))),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
                              child: Text("${studentIds.length} Học viên", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade50,
                              foregroundColor: Colors.amber.shade900,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade300)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _submitQuickFeedback(classId, c['name']),
                            icon: const Icon(Icons.flash_on_rounded),
                            label: const Text("Báo Cáo Nhanh Sau Tiết"),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH DANH SÁCH HỌC VIÊN CỦA LỚP
// ==========================================
class ClassStudentsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final List<dynamic> studentIds;

  const ClassStudentsScreen({super.key, required this.classId, required this.className, required this.studentIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: Text(className, style: const TextStyle(color: Colors.brown)),
        backgroundColor: Colors.amber.shade300,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: studentIds.isEmpty
          ? const Center(child: Text("Lớp chưa có học viên", style: TextStyle(color: Colors.brown)))
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không tải được dữ liệu"));

                var students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var s = students[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.amber.shade100, child: const Icon(Icons.person, color: Colors.brown)),
                        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                        subtitle: Text(s['studentCode'] ?? s['student_code'] ?? 'N/A'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.amber),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => StudentHistoryScreen(
                              studentId: students[index].id,
                              studentName: s['name'],
                              classId: classId,
                            )
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ==========================================
// MÀN HÌNH LỊCH SỬ ĐÁNH GIÁ CỦA 1 HỌC VIÊN
// ==========================================
class StudentHistoryScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String classId;

  const StudentHistoryScreen({super.key, required this.studentId, required this.studentName, required this.classId});

  @override
  Widget build(BuildContext context) {
    final String teacherId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: Text("Lịch sử: $studentName", style: const TextStyle(color: Colors.brown, fontSize: 18)),
        backgroundColor: Colors.amber.shade300,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports')
            .where('type', isEqualTo: 'periodic')
            .where('student_id', isEqualTo: studentId)
            .where('teacher_id', isEqualTo: teacherId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          if (snapshot.hasError) return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có đánh giá nào", style: TextStyle(color: Colors.brown)));

          var reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var r = reports[index].data() as Map<String, dynamic>;
              DateTime? date = (r['timestamp'] as Timestamp?)?.toDate();
              String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "N/A";

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(dateStr, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                          ),
                          Row(
                            children: [
                              Text("Điểm: ${r['scores'] ?? r['score']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => EvaluationFormScreen(
                                      studentId: studentId,
                                      classId: classId,
                                      reportId: reports[index].id,
                                      initialData: r,
                                    )
                                  ));
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            ],
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Text("Thái độ: ${r['attitude']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      const SizedBox(height: 8),
                      Text(r['comments'] ?? r['comment'] ?? '', style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => EvaluationFormScreen(studentId: studentId, classId: classId)
          ));
        },
        backgroundColor: Colors.amber.shade600,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm Đánh Giá", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
