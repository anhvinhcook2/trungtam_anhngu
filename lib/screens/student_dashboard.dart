import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation/auth_wrapper.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
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
        title: const Text("Xác nhận đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Hủy", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(100, 44),
            ),
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

    print("DEBUG: Đang tìm với mã: '$code'");
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
      print("DEBUG: Số lượng tìm thấy theo student_code: ${query.docs.length}");
      if (query.docs.isEmpty) {
        // Fallback for older data that might still use camelCase
        query = await _db.collection('users')
            .where('studentCode', isEqualTo: code)
            .limit(1)
            .get();
        print("DEBUG: Số lượng tìm thấy theo studentCode: ${query.docs.length}");
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ) : const SizedBox(),
        title: const Text(
          "TRA CỨU HỌC TẬP", 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2, 
            fontSize: 16, 
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: "Nhập mã số (VD: HV-2026-xxxx)",
                        hintStyle: TextStyle(color: Colors.black38, fontWeight: FontWeight.normal, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _searchStudent(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(50),
                        blurRadius: 10,
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
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.search_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          
          if (_isLoading) 
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                    const SizedBox(height: 24),
                    
                    const Text(
                      "Trạng thái học phí", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildTuitionStatusList(),
                    const SizedBox(height: 24),

                    // Navigation schedule button with beautiful styling
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleView(studentId: _studentUid))),
                        icon: const Icon(Icons.calendar_today_rounded, size: 20),
                        label: const Text("XEM THỜI KHÓA BIỂU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    const Text(
                      "Lịch Sử Đánh Giá Định Kỳ", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    
                    // 4. Danh sách Lịch sử Điểm
                    _buildReportsList(),
                  ],
                ),
              ),
            ),
            // 5. Nút Chat với Admin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserName: "Ban Hỗ Trợ (Admin)")));
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    label: const Text("TRAO ĐỔI VỚI TRUNG TÂM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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
                    Icon(Icons.school_rounded, size: 90, color: Colors.black12),
                    SizedBox(height: 16),
                    Text(
                      "Nhập mã số để tra cứu thông tin", 
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Mã số dạng HV-2026-XXXXXXXX",
                      style: TextStyle(color: Colors.black26, fontSize: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mã học viên: $studentCodeStr", 
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
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
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)));
        }
        if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withAlpha(10)),
            ),
            child: const Text("Chưa đăng ký lớp học nào.", style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
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
                Color statusColor = Colors.redAccent;
                Color bgColor = Colors.red.shade50;
                if (tuitionSnapshot.hasData && tuitionSnapshot.data!.docs.isNotEmpty) {
                  status = tuitionSnapshot.data!.docs.first['status'] == 'paid' ? "Đã đóng" : "Đang xử lý";
                  statusColor = status == "Đã đóng" ? Colors.green : Colors.orange;
                  bgColor = status == "Đã đóng" ? Colors.green.shade50 : Colors.orange.shade50;
                }
                
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withAlpha(10)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.class_rounded, color: Color(0xFF2563EB)),
                    ),
                    title: Text(
                      classData['name'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      "Lớp: ${classData['room'] ?? 'N/A'}",
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status, 
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
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
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primaryColor)));
        }
        if (snapshot.hasError) return Text("Lỗi: ${snapshot.error}");
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withAlpha(10)),
            ),
            child: const Center(
              child: Text(
                "Học viên chưa có dữ liệu điểm số.", 
                style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(color: Colors.black.withAlpha(10)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withAlpha(30)),
                          ),
                          child: Text(
                            "Điểm: ${r['scores'] ?? r['score']}", 
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    Row(
                      children: [
                        const Text(
                          "Thái độ: ", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                        ),
                        Text(
                          r['attitude'] ?? 'N/A', 
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Nhận xét của giáo viên:", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r['comments'] ?? r['comment'] ?? 'Chưa có nhận xét.', 
                        style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                      ),
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
