import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import 'student_progression_screen.dart';

class AdminStudentManagement extends StatefulWidget {
  const AdminStudentManagement({super.key});

  @override
  State<AdminStudentManagement> createState() => _AdminStudentManagementState();
}

class _AdminStudentManagementState extends State<AdminStudentManagement> {
  final _db = FirebaseFirestore.instance;
  final _fs = FirebaseService();
  bool _isProcessing = false;

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  // Helper cho giao diện Input
  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: _bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Thêm Học Viên Mới", 
            style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 18),
          ),
          content: _isProcessing 
            ? SizedBox(
                height: 100, 
                child: Center(child: CircularProgressIndicator(color: _primaryColor)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC, 
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                    decoration: _customInputDecoration("Họ và tên"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailC, 
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                    decoration: _customInputDecoration("Email"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passC, 
                    obscureText: true,
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                    decoration: _customInputDecoration("Mật khẩu"),
                  ),
                ],
              ),
          actions: _isProcessing ? [] : [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.length < 6) return;
                setDialogState(() => _isProcessing = true);
                FirebaseApp? tempApp;
                try {
                  tempApp = await _fs.createSecondaryInstance();
                  UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
                    email: emailC.text.trim(), password: passC.text.trim());
                  
                  String sCode = _fs.generateStudentCode();
                  await _db.collection('users').doc(res.user!.uid).set({
                    'uid': res.user!.uid, 'email': emailC.text, 'name': nameC.text, 
                    'role': 'student', 'student_code': sCode, 'tuition_status': 'Chưa đóng',
                    'updatedAt': FieldValue.serverTimestamp()
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm học viên thành công!"), backgroundColor: Colors.green));
                } finally {
                  await tempApp?.delete();
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: Text("Lưu Hồ Sơ", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String uid, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Sửa thông tin", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 18)),
        content: TextField(
          controller: nameCtrl, 
          style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
          decoration: _customInputDecoration("Họ và tên mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _db.collection('users').doc(uid).update({'name': nameCtrl.text});
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật tên!"), backgroundColor: Colors.green));
              }
            },
            child: Text("Lưu", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(String uid, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Xác nhận xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 18)),
        content: Text(
          "Xóa học viên $email?\nBạn cần vào Firebase Console để xóa tài khoản Auth thủ công!",
          style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700], height: 1.5),
        ),
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
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.collection('users').doc(uid).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa hồ sơ."), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Học Viên Hệ Thống", 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900, fontSize: 18, color: _primaryColor, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _primaryColor));
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Chưa có học viên nào.", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Text(
                            doc['name'][0].toUpperCase(), 
                            style: TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 22),
                          ),
                        ),
                      ),
                      title: Text(
                        doc['name'], 
                        style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['student_code'] ?? doc['studentCode'] ?? "Chưa cấp mã", 
                              style: TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doc['email'], 
                              style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      trailing: SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildStudentDebtSummary(doc.id),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProgressionScreen(studentId: doc.id, studentName: doc['name']))),
                            icon: Icon(Icons.timeline_rounded, size: 18, color: _accentColor), // Màu Cam nhạt
                            label: Text("Lộ trình", style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.w700)),
                          ),
                          TextButton.icon(
                            onPressed: () => _showEditDialog(doc.id, doc['name']),
                            icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF3B82F6)), // Xanh dương mượt
                            label: Text("Sửa", style: TextStyle(fontFamily: _fontFamily, color: Color(0xFF3B82F6), fontWeight: FontWeight.w700)),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteStudent(doc.id, doc['email']),
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                            label: Text("Xóa", style: TextStyle(fontFamily: _fontFamily, color: Colors.red.shade400, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: _primaryColor, // Deep Jungle Green
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(
          "THÊM HỌC VIÊN",
          style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc 16px
      ),
    );
  }

  Widget _buildStudentDebtSummary(String studentId) {
    String month = DateTime.now().toString().substring(0, 7);
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('tuition')
          .where('studentId', isEqualTo: studentId)
          .where('month', isEqualTo: month)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Trạng thái: Đã đóng
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Đã đóng", 
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _fontFamily, color: const Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 12),
            ),
          );
        }
        
        // Trạng thái: Nợ môn
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Nợ ${snapshot.data!.docs.length} môn", 
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: _fontFamily, color: Colors.red.shade600, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        );
      },
    );
  }
}