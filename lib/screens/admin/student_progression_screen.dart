import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressionScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentProgressionScreen({super.key, required this.studentId, required this.studentName});

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Lộ Trình: $studentName",
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: _primaryColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        shape: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('studentIds', arrayContains: studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))]
                    ),
                    child: Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Học viên chưa tham gia lộ trình nào.",
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          var classes = snapshot.data!.docs;

          // ĐÃ SỬA LỖI PADDING Ở ĐÂY BẰNG CÁCH BỌC TRONG THẺ PADDING
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: CustomScrollView(
              slivers: [
                // HEADER TỔNG QUAN
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, const Color(0xFF00695C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tổng quan lộ trình",
                                style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Đã tham gia ${classes.length} khóa học",
                                style: TextStyle(fontFamily: _fontFamily, color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // TIMELINE DANH SÁCH LỚP HỌC
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var data = classes[index].data() as Map<String, dynamic>;
                      bool isLast = index == classes.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Thanh Timeline dọc
                            SizedBox(
                              width: 30,
                              child: Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _primaryColor, width: 4),
                                      boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: _primaryColor.withValues(alpha: 0.2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Thẻ Nội dung lớp học
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['name'] ?? 'Chưa có tên',
                                            style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                                          ),
                                        ),
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24), // Xanh lá đã hoàn thành / đang học
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Hiển thị Pill (Viên thuốc) cho Cấp độ và Môn học
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _primaryColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.leaderboard_rounded, size: 14, color: _primaryColor),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Cấp độ: ${data['level'] ?? 'N/A'}",
                                                style: TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.menu_book_rounded, size: 14, color: _accentColor),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Môn: ${data['subject'] ?? 'N/A'}",
                                                style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: classes.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
