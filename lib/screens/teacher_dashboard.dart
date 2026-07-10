import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/auth_wrapper.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'evaluation_form.dart';
import 'schedule_view.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _submitQuickFeedback(String classId, String className) async {
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Báo Cáo Nhanh\nLớp: $className", style: const TextStyle(color: AppTheme.primaryColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: TextField(
          controller: contentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Nhập tình hình lớp học hôm nay...",
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi báo cáo nhanh!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("GIẢNG VIÊN", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleView(teacherId: currentUser!.uid))),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Xác nhận"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
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
              if (confirm) {
                await _authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthWrapper()), (route) => false);
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('classes').where('teacherId', isEqualTo: currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Bạn chưa được phân công lớp nào.", style: TextStyle(color: AppTheme.textSecondary)));

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var c = classes[index].data() as Map<String, dynamic>;
              String classId = classes[index].id;
              List<dynamic> studentIds = c['studentIds'] ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassStudentsScreen(classId: classId, className: c['name'], studentIds: studentIds))),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                              child: Text("${studentIds.length} Học viên", style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () => _submitQuickFeedback(classId, c['name']),
                          icon: const Icon(Icons.flash_on_rounded),
                          label: const Text("BÁO CÁO NHANH SAU TIẾT"),
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

class ClassStudentsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final List<dynamic> studentIds;

  const ClassStudentsScreen({super.key, required this.classId, required this.className, required this.studentIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(className, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primaryColor),
            onPressed: () => _showAttendanceDialog(context),
          ),
        ],
      ),
      body: studentIds.isEmpty
          ? const Center(child: Text("Lớp chưa có học viên", style: TextStyle(color: AppTheme.textSecondary)))
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không tải được dữ liệu"));

                var students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var s = students[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withAlpha(20), child: const Icon(Icons.person, color: AppTheme.primaryColor)),
                        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        subtitle: Text(s['studentCode'] ?? s['student_code'] ?? 'N/A'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
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

  void _showAttendanceDialog(BuildContext context) async {
    final students = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: studentIds).get();
    Map<String, String> attendance = {for (var s in students.docs) s.id: 'present'};
    String dateStr = DateTime.now().toString().split(' ')[0];

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text("Điểm danh ngày $dateStr"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.docs.length,
              itemBuilder: (context, i) {
                var s = students.docs[i];
                return ListTile(
                  title: Text(s['name']),
                  trailing: DropdownButton<String>(
                    value: attendance[s.id],
                    onChanged: (v) => setDialogState(() => attendance[s.id] = v!),
                    items: ['present', 'absent', 'late'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: () async {
              await FirebaseFirestore.instance.collection('attendance').add({
                'classId': classId,
                'date': dateStr,
                'records': attendance,
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm danh!")));
            }, child: const Text("Lưu")),
          ],
        );
      }),
    );
  }
}

class StudentHistoryScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String classId;

  const StudentHistoryScreen({super.key, required this.studentId, required this.studentName, required this.classId});

  @override
  Widget build(BuildContext context) {
    final String teacherId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Lịch sử: $studentName", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports')
            .where('type', isEqualTo: 'periodic')
            .where('student_id', isEqualTo: studentId)
            .where('teacher_id', isEqualTo: teacherId)
            .where('class_id', isEqualTo: classId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có đánh giá nào", style: TextStyle(color: AppTheme.textSecondary)));

          var reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var r = reports[index].data() as Map<String, dynamic>;
              DateTime? date = (r['timestamp'] as Timestamp?)?.toDate();
              String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "N/A";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(dateStr, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        Row(
                          children: [
                            Text("Điểm: ${r['scores'] ?? r['score']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _deleteReport(context, reports[index].id),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(),
                    Text("Thái độ: ${r['attitude']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(r['comments'] ?? r['comment'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                  ],
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
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm Đánh Giá", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _deleteReport(BuildContext context, String reportId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa đánh giá này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa đánh giá!")));
    }
  }
}
