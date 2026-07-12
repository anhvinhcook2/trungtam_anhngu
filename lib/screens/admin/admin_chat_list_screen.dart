import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final String _fontFamily = 'Nunito';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        ),
        title: Text(
          "Hộp Thư Hỗ Trợ",
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w900,
            color: _primaryColor, // Deep Jungle Green
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Trạng thái trống (Empty State)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có cuộc trò chuyện nào.",
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          var chats = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: chats.length,
            itemBuilder: (context, i) {
              var chat = chats[i];
              final data = chat.data() as Map<String, dynamic>?;
              String studentName =
                  (data?['studentName'] as String?) ??
                  (data?['student_name'] as String?) ??
                  'Học viên ẩn danh';

              String lastMsg = (data?['lastMessage'] as String?) ?? '';
              Timestamp? updatedTs = data?['updatedAt'] as Timestamp?;
              String timeStr = '';
              if (updatedTs != null) {
                DateTime dt = updatedTs.toDate();
                timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: _primaryColor.withValues(alpha: 0.08),
                    child: Icon(Icons.person_rounded, color: _primaryColor, size: 24),
                  ),
                  title: Text(
                    studentName,
                    style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  subtitle: Text(
                    lastMsg.isNotEmpty ? lastMsg : 'Nhấn để xem chi tiết trò chuyện',
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(height: 8),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: chat.id, otherUserName: studentName),
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
