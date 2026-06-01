import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportInbox extends StatefulWidget {
  const AdminSupportInbox({super.key});

  @override
  State<AdminSupportInbox> createState() => _AdminSupportInboxState();
}

class _AdminSupportInboxState extends State<AdminSupportInbox> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _filter = 'Chưa đọc';

  Future<void> _markAsResolved(String requestId) async {
    await _db.collection('supportTickets').doc(requestId).update({
      'status': 'Đã đọc',
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã đánh dấu Đã đọc!"), backgroundColor: Colors.green),
    );
  }

  void _showReplyDialog(String requestId, String message) {
    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Phản hồi học viên"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hỏi: $message", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Nhập phản hồi...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (replyCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _db.collection('supportTickets').doc(requestId).update({
                  'status': 'Đã đọc',
                  'reply': replyCtrl.text,
                  'repliedAt': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã phản hồi!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hộp Thư Hỗ Trợ"),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Chưa đọc"),
                  selected: _filter == 'Chưa đọc',
                  onSelected: (val) {
                    if (val) setState(() => _filter = 'Chưa đọc');
                  },
                  selectedColor: const Color(0xFF4F46E5).withAlpha(51),
                  labelStyle: TextStyle(color: _filter == 'Chưa đọc' ? const Color(0xFF4F46E5) : Colors.black54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Tất cả"),
                  selected: _filter == 'Tất cả',
                  onSelected: (val) {
                    if (val) setState(() => _filter = 'Tất cả');
                  },
                  selectedColor: const Color(0xFF4F46E5).withAlpha(51),
                  labelStyle: TextStyle(color: _filter == 'Tất cả' ? const Color(0xFF4F46E5) : Colors.black54, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('supportTickets')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Hộp thư trống."));

                  var allDocs = snapshot.data!.docs;
                  var filteredDocs = allDocs.where((doc) {
                    if (_filter == 'Tất cả') return true;
                    var data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'Chưa đọc' || data['status'] == 'Chờ xử lý';
                  }).toList();

                  if (filteredDocs.isEmpty) return const Center(child: Text("Không có tin nhắn phù hợp."));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      bool isUnread = data['status'] == 'Chưa đọc' || data['status'] == 'Chờ xử lý';
                      
                      DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();
                      String dateStr = date != null ? "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2,'0')}" : "";

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isUnread ? const Color(0xFF4F46E5).withAlpha(128) : Colors.transparent)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Mã HV: ${data['student_code'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4F46E5))),
                                  Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showReplyDialog(doc.id, data['message'] ?? ''),
                                    icon: const Icon(Icons.reply_rounded, size: 18),
                                    label: const Text("Phản hồi"),
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _markAsResolved(doc.id),
                                      icon: const Icon(Icons.check_rounded, size: 18),
                                      label: const Text("Đã xử lý"),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    ),
                                  ]
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
            ),
          ),
        ],
      ),
    );
  }
}
