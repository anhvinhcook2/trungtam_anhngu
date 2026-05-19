import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // HÀM 1: GỬI BÁO CÁO NHANH
  Future<void> _submitQuickFeedback(String classId, String className, String content) async {
    await _db.collection('reports').add({
      'type': 'quick',
      'class_id': classId,
      'class_name': className,
      'teacher_id': currentUser!.uid,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // HÀM 2: LƯU ĐÁNH GIÁ ĐỊNH KỲ (Hỗ trợ cả THÊM MỚI và CẬP NHẬT)
  Future<void> _submitPeriodicEvaluation({
    String? reportId,
    required String studentId,
    required String classId,
    required String score,
    required String attitude,
    required String comment
  }) async {
    if (reportId == null) {
      // Nếu không có reportId -> Là Thêm mới
      await _db.collection('reports').add({
        'type': 'periodic',
        'student_id': studentId,
        'class_id': classId,
        'teacher_id': currentUser!.uid,
        'score': score,
        'attitude': attitude,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Nếu có reportId -> Là Cập nhật (Sửa)
      await _db.collection('reports').doc(reportId).update({
        'score': score,
        'attitude': attitude,
        'comment': comment,
        // Không cập nhật lại timestamp để giữ nguyên ngày đánh giá ban đầu
      });
    }
  }

  // DIALOG: BÁO CÁO NHANH
  void _showQuickFeedbackDialog(String classId, String className) {
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Báo cáo nhanh\nLớp: $className"),
        content: TextField(
          controller: contentController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Nhập tình hình lớp học...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              if (contentController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                await _submitQuickFeedback(classId, className, contentController.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi báo cáo!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Gửi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // DIALOG: FORM NHẬP / SỬA ĐÁNH GIÁ
  void _showEvaluationInputDialog(String studentId, String classId, {String? reportId, String? currentScore, String? currentAttitude, String? currentComment}) {
    final scoreController = TextEditingController(text: currentScore);
    final attitudeController = TextEditingController(text: currentAttitude);
    final commentController = TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(reportId == null ? "Thêm Đánh Giá Mới" : "Sửa Đánh Giá"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: scoreController, decoration: const InputDecoration(labelText: "Điểm số (VD: 8.5)")),
              const SizedBox(height: 10),
              TextField(controller: attitudeController, decoration: const InputDecoration(labelText: "Thái độ học tập")),
              const SizedBox(height: 10),
              TextField(controller: commentController, maxLines: 3, decoration: const InputDecoration(labelText: "Nhận xét chi tiết")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (scoreController.text.isNotEmpty && commentController.text.isNotEmpty) {
                Navigator.pop(dialogContext); // Đóng form nhập liệu
                await _submitPeriodicEvaluation(
                    reportId: reportId,
                    studentId: studentId,
                    classId: classId,
                    score: scoreController.text,
                    attitude: attitudeController.text,
                    comment: commentController.text
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu đánh giá!"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ Điểm và Nhận xét")));
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // BOTTOM SHEET: LỊCH SỬ ĐÁNH GIÁ CỦA 1 HỌC VIÊN
  void _showStudentEvaluationHistory(String studentId, String studentName, String classId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, // Chiếm 85% màn hình
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("Lịch sử: $studentName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Truy vấn lấy các báo cáo của riêng học viên này trong lớp này, mới nhất xếp trên
                stream: _db.collection('reports')
                    .where('type', isEqualTo: 'periodic')
                    .where('student_id', isEqualTo: studentId)
                    .where('class_id', isEqualTo: classId)
                    .where('teacher_id', isEqualTo: currentUser!.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Học viên này chưa có đánh giá nào."));

                  var reports = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reports.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      var r = reports[index];
                      DateTime? date = (r['timestamp'] as Timestamp?)?.toDate();
                      String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "Mới đây";

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Ngày: $dateStr", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  Row(
                                    children: [
                                      Text("Điểm: ${r['score']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                                      const SizedBox(width: 10),
                                      // NÚT SỬA ĐÁNH GIÁ
                                      InkWell(
                                        onTap: () => _showEvaluationInputDialog(
                                            studentId, classId,
                                            reportId: r.id,
                                            currentScore: r['score'],
                                            currentAttitude: r['attitude'],
                                            currentComment: r['comment']
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text("Thái độ: ${r['attitude']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text("Nhận xét: ${r['comment']}"),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _showEvaluationInputDialog(studentId, classId),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Thêm Đánh Giá Mới", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // BOTTOM SHEET: DANH SÁCH HỌC VIÊN TRONG LỚP
  void _showClassStudents(List<dynamic> studentIds, String classId) {
    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lớp này chưa có học viên nào.")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Chọn Học viên để Đánh giá", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _db.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Không tải được dữ liệu."));

                  final students = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var s = students[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
                        title: Text("${s['name']} (${s['student_code']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Học phí: ${s['tuition_status']}"),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Đóng danh sách học viên và mở Lịch sử đánh giá của học viên đó
                            Navigator.pop(sheetContext);
                            _showStudentEvaluationHistory(s.id, s['name'], classId);
                          },
                          child: const Text("Lịch sử / Đánh giá"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giáo Viên"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('classes').where('teacher_id', isEqualTo: currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Bạn chưa được phân công lớp nào."));

          final classes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: classes.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              var c = classes[index];
              List<dynamic> studentIds = c['student_ids'] ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          Chip(label: Text("${studentIds.length} học viên")),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showQuickFeedbackDialog(c.id, c['name']),
                            icon: const Icon(Icons.flash_on, color: Colors.orange),
                            label: const Text("Báo cáo nhanh"),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showClassStudents(studentIds, c.id),
                            icon: const Icon(Icons.checklist, color: Colors.white),
                            label: const Text("Đánh giá định kỳ", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          ),
                        ],
                      )
                    ],
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