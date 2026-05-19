import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm cập nhật trạng thái xử lý
  Future<void> _markAsResolved(String requestId) async {
    await _db.collection('support_requests').doc(requestId).update({
      'status': 'Đã xử lý',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đánh dấu xử lý xong!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hộp thư Hỗ trợ"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy danh sách yêu cầu, sắp xếp mới nhất lên đầu
        stream: _db.collection('support_requests').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Hiện không có yêu cầu hỗ trợ nào."));

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              var req = requests[index];
              bool isResolved = req['status'] == 'Đã xử lý';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lấy thông tin ID học viên để Admin biết ai gửi
                          Text("Từ UID Học viên: ${req['student_id'].toString().substring(0, 6)}...", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Chip(
                            label: Text(req['status'], style: TextStyle(color: isResolved ? Colors.green : Colors.red)),
                            backgroundColor: isResolved ? Colors.green.shade50 : Colors.red.shade50,
                          )
                        ],
                      ),
                      const Divider(),
                      Text("Nội dung: ${req['content']}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      if (!isResolved)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _markAsResolved(req.id),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Đánh dấu Đã xử lý", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
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