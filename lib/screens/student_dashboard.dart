import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation/auth_wrapper.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart'; // Vẫn giữ import nếu bạn cần
import 'auth_screen.dart';
import 'schedule_view.dart';
import 'chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _studentData;
  String? _studentUid;

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px
        backgroundColor: Colors.white,
        title: Text("Xác nhận đăng xuất", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Text("Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Đăng xuất", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _searchStudent() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng đăng nhập để tra cứu!"), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String code = _searchController.text.trim().toUpperCase();

    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _studentData = null;
      _studentUid = null;
    });

    try {
      // Tìm kiếm user theo student_code (snake_case mới)
      QuerySnapshot query = await _db.collection('users')
          .where('student_code', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        // Fallback for older data that might still use camelCase
        query = await _db.collection('users')
            .where('studentCode', isEqualTo: code)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        setState(() {
          _studentData = query.docs.first.data() as Map<String, dynamic>;
          _studentUid = query.docs.first.id;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Không tìm thấy học viên với mã này"), 
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tìm kiếm: $e"), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ) : const SizedBox(),
        title: Text(
          "TRA CỨU HỌC TẬP", 
          style: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2, 
            fontSize: 16, 
            color: _primaryColor, // Đổi sang Deep Jungle Green
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
            tooltip: "Thoát hệ thống",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Modern Flat Search Bar with Soft Glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _bgColor, // Đồng bộ màu nền xám nhạt
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Nhập mã số (VD: HV-2026-xxxx)",
                        hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontWeight: FontWeight.normal, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.badge_outlined, color: _primaryColor),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _searchStudent(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _primaryColor, // Dùng màu chủ đạo cho nút search
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _searchStudent,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.search_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          
          if (_isLoading) 
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            ),
          
          if (!_isLoading && _studentData != null) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Card Thông tin Học viên
                    _buildStudentInfoCard(),
                    const SizedBox(height: 28),
                    
                    Text(
                      "Trạng thái học phí", 
                      style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildTuitionStatusList(),
                    const SizedBox(height: 24),

                    // Nút Xem thời khóa biểu
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor, // Deep Jungle Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleView(studentId: _studentUid))),
                        icon: const Icon(Icons.calendar_today_rounded, size: 20),
                        label: Text("XEM THỜI KHÓA BIỂU", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      "Lịch Sử Đánh Giá Định Kỳ", 
                      style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    
                    // 4. Danh sách Lịch sử Điểm
                    _buildReportsList(),
                  ],
                ),
              ),
            ),
            // 5. Nút Chat với Admin - Pinned Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var chatQuery = await _db.collection('chats').where('studentId', isEqualTo: _studentUid).get();
                      String chatId;
                      if (chatQuery.docs.isEmpty) {
                        var newChat = await _db.collection('chats').add({'studentId': _studentUid, 'studentName': _studentData!['name']});
                        chatId = newChat.id;
                      } else {
                        chatId = chatQuery.docs.first.id;
                      }
                      if (!context.mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserName: "Ban Hỗ Trợ (Admin)")));
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    label: Text("TRAO ĐỔI VỚI TRUNG TÂM", style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor, // Vàng nghệ / Cam nhạt cho nút CTA
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            )
          ] else if (!_isLoading) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Icon(Icons.school_rounded, size: 64, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Nhập mã số để tra cứu thông tin", 
                      style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Mã số dạng HV-2026-XXXXXXXX",
                      style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[400], fontSize: 13),
                    )
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    String studentCodeStr = _studentData!['student_code'] ?? _studentData!['studentCode'] ?? 'N/A';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor, // Thay bằng màu Deep Jungle Green
        borderRadius: BorderRadius.circular(16), // Bo góc 16px
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentData!['name'] ?? 'N/A', 
                  style: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Mã HV: $studentCodeStr", 
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionStatusList() {
    String month = DateTime.now().toString().substring(0, 7);
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('classes').where('studentIds', arrayContains: _studentUid).snapshots(),
      builder: (context, classSnapshot) {
        if (classSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 3, color: _primaryColor)));
        }
        if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text("Chưa đăng ký lớp học nào.", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontStyle: FontStyle.italic)),
          );
        }
        
        var classes = classSnapshot.data!.docs;
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            var classData = classes[index].data() as Map<String, dynamic>;
            var classId = classes[index].id;
            
            return FutureBuilder<QuerySnapshot>(
              future: _db.collection('tuition')
                  .where('studentId', isEqualTo: _studentUid)
                  .where('classId', isEqualTo: classId)
                  .where('month', isEqualTo: month)
                  .get(),
              builder: (context, tuitionSnapshot) {
                String status = "Chưa đóng";
                Color statusColor = Colors.red.shade600;
                Color bgColor = Colors.red.shade50;
                
                if (tuitionSnapshot.hasData && tuitionSnapshot.data!.docs.isNotEmpty) {
                  status = tuitionSnapshot.data!.docs.first['status'] == 'paid' ? "Đã đóng" : "Đang xử lý";
                  statusColor = status == "Đã đóng" ? const Color(0xFF10B981) : _accentColor;
                  bgColor = status == "Đã đóng" ? const Color(0xFF10B981).withValues(alpha: 0.1) : _accentColor.withValues(alpha: 0.1);
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.class_rounded, color: _primaryColor, size: 20),
                    ),
                    title: Text(
                      classData['name'], 
                      style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Phòng: ${classData['room'] ?? 'N/A'}",
                        style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status, 
                        style: TextStyle(fontFamily: _fontFamily, color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports')
          .where('type', isEqualTo: 'periodic')
          .where('student_id', isEqualTo: _studentUid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator(color: _primaryColor)));
        }
        if (snapshot.hasError) return Text("Lỗi: ${snapshot.error}");
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                "Học viên chưa có dữ liệu điểm số.", 
                style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        var reports = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            var r = reports[index].data() as Map<String, dynamic>;
            DateTime? date = (r['timestamp'] as Timestamp?)?.toDate();
            String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "N/A";

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
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
                          Text(
                            dateStr, 
                            style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Điểm: ${r['scores'] ?? r['score']}", 
                          style: TextStyle(fontFamily: _fontFamily, color: const Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  Row(
                    children: [
                      Text(
                        "Thái độ: ", 
                        style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14),
                      ),
                      Text(
                        r['attitude'] ?? 'N/A', 
                        style: TextStyle(fontFamily: _fontFamily, color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Nhận xét của giáo viên:", 
                    style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r['comments'] ?? r['comment'] ?? 'Chưa có nhận xét.', 
                      style: TextStyle(fontFamily: _fontFamily, color: Colors.black87, fontStyle: FontStyle.italic, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
