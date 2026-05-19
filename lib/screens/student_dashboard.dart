import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// DIALOG: GỬI YÊU CẦU HỖ TRỢ ĐẾN ADMIN
  void _showSupportDialog() {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liên hệ Admin"),
        content: TextField(
          controller: contentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Nhập câu hỏi hoặc yêu cầu hỗ trợ của bạn...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              if (contentController.text.isNotEmpty) {
                // Lưu yêu cầu vào collection 'support_requests'
                await _db.collection('support_requests').add({
                  'student_id': currentUser!.uid,
                  'content': contentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'Chưa xử lý',
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã gửi yêu cầu thành công! Admin sẽ sớm phản hồi."), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text("Gửi đi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Lỗi: Không tìm thấy phiên đăng nhập.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Học Viên & Phụ Huynh"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          /// PHẦN 1: THÔNG TIN HỌC VIÊN & HỌC PHÍ
          StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('users').doc(currentUser!.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Không tải được dữ liệu học viên."));
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              bool isPaid = userData['tuition_status'] == 'Đã đóng';

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Xin chào, ${userData['name']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const Icon(Icons.face, color: Colors.teal, size: 30),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Mã số học viên: ${userData['student_code']}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Trạng thái học phí: ", style: TextStyle(fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userData['tuition_status'] ?? 'Chưa rõ',
                              style: TextStyle(color: isPaid ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _showSupportDialog,
                          icon: const Icon(Icons.support_agent, color: Colors.teal),
                          label: const Text("Liên hệ / Phản hồi Admin", style: TextStyle(color: Colors.teal)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("KẾT QUẢ HỌC TẬP (2 TUẦN)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          /// PHẦN 2: DANH SÁCH ĐÁNH GIÁ TỪ GIÁO VIÊN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Truy vấn: Lấy các báo cáo loại 'periodic' và đúng ID của học viên này
              stream: _db.collection('reports')
                  .where('type', isEqualTo: 'periodic')
                  .where('student_id', isEqualTo: currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bạn chưa có bài đánh giá nào."));
                }

                var reports = snapshot.data!.docs;

                // Sắp xếp danh sách mới nhất lên đầu (do thiếu Index Firebase nên xếp ở client)
                var sortedReports = reports.toList()..sort((a, b) {
                  Timestamp? tA = (a.data() as Map<String, dynamic>)['timestamp'];
                  Timestamp? tB = (b.data() as Map<String, dynamic>)['timestamp'];
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  itemCount: sortedReports.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    var r = sortedReports[index].data() as Map<String, dynamic>;

                    // Lấy ngày tháng định dạng cơ bản
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
                                Text("Điểm số: ${r['score']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                              ],
                            ),
                            const Divider(),
                            Text("Thái độ học tập: ${r['attitude']}"),
                            const SizedBox(height: 5),
                            Text("Nhận xét của Giáo viên: ${r['comment']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}