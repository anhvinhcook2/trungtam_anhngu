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
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
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
                          color: Colors.black.withOpacity(0.03),
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

          var chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: chats.length,
            itemBuilder: (context, i) {
              var chat = chats[i];
              String studentName = chat['studentName'] ?? 'Học viên ẩn danh';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Bo góc 16px
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03), // Bóng đổ mờ
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chat.id, 
                          otherUserName: studentName,
                        )
                      )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar mờ (Light variant của Primary Color)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded, color: _primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          
                          // Tên học viên
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Nhấn để xem chi tiết trò chuyện",
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Mũi tên điều hướng
                          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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