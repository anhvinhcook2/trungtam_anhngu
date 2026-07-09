import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _searchStudent() async {
    String code = _searchController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _studentData = null;
      _studentUid = null;
    });

    try {
      // Tìm kiếm user theo studentCode
      QuerySnapshot query = await _db.collection('users')
          .where('studentCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Fallback for older data that might use student_code
        query = await _db.collection('users')
            .where('student_code', isEqualTo: code)
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy học viên với mã này"), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tìm kiếm: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9), // Xanh pastel cực nhạt
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4F46E5)),
          onPressed: () => Navigator.pop(context),
        ) : const SizedBox(),
        title: const Text("TRA CỨU HỌC TẬP", 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text("THOÁT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm Flat Design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Nhập mã số (VD: HV-2026-xxxx)",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _searchStudent(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _searchStudent,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          
          if (_isLoading) const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.amber)),
          
          if (!_isLoading && _studentData != null) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Card Thông tin Học viên
                    _buildStudentInfoCard(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleView(studentId: _studentUid))),
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: const Text("XEM THỜI KHÓA BIỂU"),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text("Lịch Sử Đánh Giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    // 4. Danh sách Lịch sử Điểm
                    _buildReportsList(),
                  ],
                ),
              ),
            ),
            // 5. Nút Chat với Admin
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Lấy hoặc tạo chatId cho học viên
                    var chatQuery = await _db.collection('chats').where('studentId', isEqualTo: _studentUid).get();
                    String chatId;
                    if (chatQuery.docs.isEmpty) {
                      var newChat = await _db.collection('chats').add({'studentId': _studentUid, 'studentName': _studentData!['name']});
                      chatId = newChat.id;
                    } else {
                      chatId = chatQuery.docs.first.id;
                    }
                    if (!context.mounted) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserName: "Admin")));
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  label: const Text("CHAT VỚI ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            )
          ] else if (!_isLoading) ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_rounded, size: 80, color: Colors.black12),
                    SizedBox(height: 16),
                    Text("Nhập mã số để tra cứu thông tin", style: TextStyle(color: Colors.black38, fontSize: 16)),
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
    String status = _studentData!['tuitionStatus'] ?? _studentData!['tuition_status'] ?? 'Chưa đóng';
    bool isPaid = status == 'Đã đóng';
    
    DateTime? updateDate;
    if (_studentData!['updatedAt'] != null) {
      if (_studentData!['updatedAt'] is int) {
        updateDate = DateTime.fromMillisecondsSinceEpoch(_studentData!['updatedAt']);
      } else if (_studentData!['updatedAt'] is Timestamp) {
        updateDate = (_studentData!['updatedAt'] as Timestamp).toDate();
      }
    }
    String updateStr = updateDate != null ? "${updateDate.day}/${updateDate.month}/${updateDate.year}" : "N/A";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_studentData!['name'] ?? 'N/A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Mã số: ${_studentData!['studentCode'] ?? _studentData!['student_code'] ?? 'N/A'}", style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Học phí:", style: TextStyle(fontSize: 16, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFF4CAF50).withAlpha(38) : const Color(0xFFEF5350).withAlpha(38), // 0.15 * 255 ≈ 38
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text("Cập nhật lần cuối: $updateStr", style: const TextStyle(fontSize: 12, color: Colors.black38)),
        ],
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        if (snapshot.hasError) return Text("Lỗi: ${snapshot.error}");
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("Học viên chưa có dữ liệu điểm số.", style: TextStyle(color: Colors.black54));

        var reports = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            var r = reports[index].data() as Map<String, dynamic>;
            DateTime? date = (r['timestamp'] as Timestamp?)?.toDate();
            String dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "N/A";

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text("Điểm: ${r['scores'] ?? r['score']}", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("Thái độ: ${r['attitude'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: "Nhận xét từ giáo viên",
                      child: Text(r['comments'] ?? r['comment'] ?? '', style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
