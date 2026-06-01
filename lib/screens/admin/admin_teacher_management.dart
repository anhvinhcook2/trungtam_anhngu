import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

class AdminTeacherManagement extends StatefulWidget {
  const AdminTeacherManagement({super.key});

  @override
  State<AdminTeacherManagement> createState() => _AdminTeacherManagementState();
}

class _AdminTeacherManagementState extends State<AdminTeacherManagement> {
  final _fs = FirebaseService();
  final _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  void _showAddDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thêm Giáo Viên Mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Họ và tên")),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passC, decoration: const InputDecoration(labelText: "Mật khẩu"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              Navigator.pop(context);
              FirebaseApp? tempApp;
              try {
                tempApp = await _fs.createSecondaryInstance();
                UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
                    email: emailC.text.trim(), password: passC.text.trim());
                await _db.collection('users').doc(res.user!.uid).set({
                  'uid': res.user!.uid, 'name': nameC.text, 'email': emailC.text,
                  'role': 'teacher', 'updatedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm giáo viên thành công!")));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              } finally {
                await tempApp?.delete();
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  void _showEditDialog(String uid, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sửa tên giáo viên"),
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

  Future<void> _deleteTeacher(String uid, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text("Bạn đang xóa dữ liệu của giáo viên: $email\n\nLưu ý: Bạn cần vào mục Authentication trên Firebase Console để xóa thủ công tài khoản này!"),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa hồ sơ giáo viên!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Giáo viên")),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showEditDialog(doc.id, doc['name'])),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTeacher(doc.id, doc['email']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, backgroundColor: Colors.indigo, child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
