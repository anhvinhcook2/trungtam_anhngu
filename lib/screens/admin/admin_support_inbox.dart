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

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bo góc 24px
        title: Text(
          "Phản hồi học viên", 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.1)),
              ),
              child: Text(
                "Hỏi: $message", 
                style: TextStyle(fontFamily: _fontFamily, fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
              decoration: InputDecoration(
                hintText: "Nhập phản hồi của bạn...",
                hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[400]),
                filled: true,
                fillColor: _bgColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
              ),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (replyCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _db.collection('supportTickets').doc(requestId).update({
                  'status': 'Đã đọc',
                  'reply': replyCtrl.text,
                  'repliedAt': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi phản hồi!"), backgroundColor: Colors.green));
              }
            },
            child: Text("Gửi", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Hộp Thư Hỗ Trợ",
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900, fontSize: 18, color: _primaryColor, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      ),
      body: Column(
        children: [
          // BỘ LỌC (FILTER CHIPS)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                _buildFilterChip("Chưa đọc"),
                const SizedBox(width: 12),
                _buildFilterChip("Tất cả"),
              ],
            ),
          ),
          
          // DANH SÁCH TIN NHẮN
          Expanded(
            child: RefreshIndicator(
              color: _primaryColor,
              onRefresh: () async {
                setState(() {});
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('supportTickets')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _primaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState("Hộp thư hiện đang trống.");
                  }

                  var allDocs = snapshot.data!.docs;
                  var filteredDocs = allDocs.where((doc) {
                    if (_filter == 'Tất cả') return true;
                    var data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'Chưa đọc' || data['status'] == 'Chờ xử lý';
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState("Không có tin nhắn nào phù hợp với bộ lọc.");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      bool isUnread = data['status'] == 'Chưa đọc' || data['status'] == 'Chờ xử lý';
                      
                      DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();
                      String dateStr = date != null ? "${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2,'0')}" : "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20), // Bo góc 20px
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))
                          ],
                          // Thêm đường viền mờ bên trái cho tin nhắn chưa đọc
                          border: isUnread ? Border(left: BorderSide(color: _accentColor, width: 4)) : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.person_rounded, color: _primaryColor, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        data['student_code'] ?? 'N/A', 
                                        style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  if (isUnread)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                      child: Text("Mới", style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  else
                                    Text(dateStr, style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              Text(
                                data['message'] ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.grey[800], height: 1.4),
                              ),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showReplyDialog(doc.id, data['message'] ?? ''),
                                    icon: const Icon(Icons.reply_rounded, size: 18),
                                    label: Text("Phản hồi", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _primaryColor,
                                      side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _markAsResolved(doc.id),
                                      icon: const Icon(Icons.check_rounded, size: 18),
                                      label: Text("Đã xử lý", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981), // Xanh lá mượt
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
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

  // Widget Tái sử dụng cho Filter Chip
  Widget _buildFilterChip(String label) {
    bool isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = label);
      },
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: _primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        color: isSelected ? _primaryColor : Colors.grey[500], 
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? _primaryColor.withOpacity(0.3) : Colors.grey.shade300),
      ),
    );
  }

  // Widget Tái sử dụng cho Trạng thái trống
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}