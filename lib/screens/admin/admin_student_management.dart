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

  void _showAddDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Thêm Học Viên Mới", style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: _isProcessing 
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: "Họ và tên")),
                  const SizedBox(height: 12),
                  TextField(controller: emailC, decoration: const InputDecoration(labelText: "Email")),
                  const SizedBox(height: 12),
                  TextField(controller: passC, decoration: const InputDecoration(labelText: "Mật khẩu"), obscureText: true),
                ],
              ),
          actions: _isProcessing ? [] : [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
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
                    'role': 'student', 'studentCode': sCode, 'tuitionStatus': 'Chưa đóng',
                    'updatedAt': FieldValue.serverTimestamp()
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } finally {
                  await tempApp?.delete();
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text("Lưu Hồ Sơ"),
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
        title: const Text("Sửa thông tin"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Họ và tên mới")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _db.collection('users').doc(uid).update({'name': nameCtrl.text});
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật tên!")));
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(String uid, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Xóa học viên $email?\nBạn cần vào Firebase Console để xóa tài khoản Auth thủ công!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.collection('users').doc(uid).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa hồ sơ.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Học Viên Hệ Thống", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF8FAFC),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              bool isPaid = doc['tuitionStatus'] == 'Đã đóng';
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF4F46E5).withAlpha(20),
                        child: Text(doc['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(doc['studentCode'] ?? "Chưa cấp mã", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                          Text(doc['email'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isPaid,
                              activeThumbColor: const Color(0xFF16A34A),
                              activeTrackColor: const Color(0xFFF0FDF4),
                              inactiveThumbColor: const Color(0xFFDC2626),
                              inactiveTrackColor: const Color(0xFFFEF2F2),
                              onChanged: (val) async {
                                await _db.collection('users').doc(doc.id).update({'tuitionStatus': val ? 'Đã đóng' : 'Chưa đóng'});
                              },
                            ),
                          ),
                          Text(isPaid ? "ĐÃ ĐÓNG" : "NỢ PHÍ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProgressionScreen(studentId: doc.id, studentName: doc['name']))),
                          icon: const Icon(Icons.timeline_rounded, size: 18),
                          label: const Text("Lộ trình"),
                          style: TextButton.styleFrom(foregroundColor: Colors.teal),
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditDialog(doc.id, doc['name']),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text("Sửa"),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteStudent(doc.id, doc['email']),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text("Xóa"),
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        ),
                        const SizedBox(width: 16),
                      ],
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
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("THÊM HỌC VIÊN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
