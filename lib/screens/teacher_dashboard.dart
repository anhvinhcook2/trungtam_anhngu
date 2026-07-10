import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/auth_wrapper.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'evaluation_form.dart';
import 'schedule_view.dart';

// --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
const Color _primaryColor = Color(0xFF004D40); // Deep Jungle Green
const Color _bgColor = Color(0xFFF8F9FA); // Light Grey
const Color _accentColor = Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
const String _fontFamily = 'Nunito';

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Báo Cáo Nhanh\nLớp: $className", 
          style: const TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: TextField(
          controller: contentController,
          maxLines: 4,
          style: const TextStyle(fontFamily: _fontFamily, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Nhập tình hình lớp học hôm nay...",
            hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: _bgColor,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, 
              foregroundColor: Colors.white, 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            child: const Text("Gửi Báo Cáo", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return Scaffold(backgroundColor: _bgColor, body: const Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
        title: const Text(
          "GIẢNG VIÊN", 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900, fontSize: 16, color: _primaryColor, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: _primaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleView(teacherId: currentUser!.uid))),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Xác nhận", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                  content: Text("Bạn có chắc chắn muốn đăng xuất?", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700])),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text("Đăng xuất", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold))
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
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('classes').where('teacherId', isEqualTo: currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa được phân công lớp nào.", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

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
                  borderRadius: BorderRadius.circular(20), // Thẻ bo tròn 20px 
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassStudentsScreen(classId: classId, className: c['name'], studentIds: studentIds))),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  c['name'], 
                                  style: const TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text("${studentIds.length} Học viên", style: const TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Nút Báo cáo nhanh dùng Accent Color
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor.withOpacity(0.15),
                              foregroundColor: _accentColor,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () => _submitQuickFeedback(classId, c['name']),
                            icon: const Icon(Icons.flash_on_rounded, size: 20),
                            label: const Text("BÁO CÁO NHANH SAU TIẾT", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 14)),
                          )
                        ],
                      ),
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(className, style: const TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
        iconTheme: const IconThemeData(color: _primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded, color: _accentColor, size: 26),
            tooltip: "Điểm danh",
            onPressed: () => _showAttendanceDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: studentIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Lớp chưa có học viên", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            )
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryColor));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không tải được dữ liệu"));

                var students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var s = students[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person, color: _primaryColor, size: 24),
                        ),
                        title: Text(s['name'], style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            s['studentCode'] ?? s['student_code'] ?? 'N/A',
                            style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bo góc 24px
          title: Text("Điểm danh ngày $dateStr", style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.docs.length,
              itemBuilder: (context, i) {
                var s = students.docs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s['name'], style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: attendance[s.id],
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          onChanged: (v) => setDialogState(() => attendance[s.id] = v!),
                          items: [
                            const DropdownMenuItem(value: 'present', child: Text("Có mặt", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            const DropdownMenuItem(value: 'absent', child: Text("Vắng", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                            const DropdownMenuItem(value: 'late', child: Text("Trễ", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('attendance').add({
                  'classId': classId,
                  'date': dateStr,
                  'records': attendance,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm danh!"), backgroundColor: Colors.green));
              }, 
              child: const Text("Lưu", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            ),
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text("Lịch sử: $studentName", style: const TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
        iconTheme: const IconThemeData(color: _primaryColor),
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Chưa có đánh giá nào", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

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
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_note_rounded, size: 20, color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(dateStr, style: const TextStyle(fontFamily: _fontFamily, color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text("Điểm: ${r['scores'] ?? r['score']}", style: const TextStyle(fontFamily: _fontFamily, color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.grey.shade200, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text("Thái độ: ", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14)),
                              Text("${r['attitude']}", style: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 22),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
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
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () => _deleteReport(context, reports[index].id),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r['comments'] ?? r['comment'] ?? '', 
                      style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 14, height: 1.4),
                    ),
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
        backgroundColor: _accentColor, // Vàng / Cam
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm Đánh Giá", style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  void _deleteReport(BuildContext context, String reportId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc chắn muốn xóa đánh giá này?", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa đánh giá!"), backgroundColor: Colors.green));
    }
  }
}