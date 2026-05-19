import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isProcessing = false;

  /// HÀM THÊM GIÁO VIÊN: Sử dụng App phụ để không văng Admin
  Future<void> _addTeacher(String name, String email, String password) async {
    setState(() => _isProcessing = true);

    String tempAppName = "TeacherApp_${DateTime.now().millisecondsSinceEpoch}";
    FirebaseApp? tempApp;

    try {
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential res = await tempAuth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'name': name,
        'email': email,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã thêm giáo viên thành công!"), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi: ${e.message}";
      // Bắt lỗi Email đã tồn tại (do xóa tay chưa sạch)
      if (e.code == 'email-already-in-use') {
        msg = "Email này vẫn còn trong hệ thống Auth. Hãy vào Firebase Console -> Authentication để xóa hoàn toàn!";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e"), backgroundColor: Colors.red));
    } finally {
      await tempApp?.delete();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// HÀM XÓA THỦ CÔNG: Chỉ xóa dữ liệu trên Firestore
  Future<void> _deleteTeacher(String uid, String email) async {
    bool confirm = await _showConfirmDialog(email);

    if (confirm) {
      setState(() => _isProcessing = true);
      try {
        // Chỉ xóa Document trong Collection 'users'
        await _db.collection('users').doc(uid).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xóa hồ sơ! Vui lòng vào Firebase Console để xóa email đăng nhập."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi xóa hồ sơ: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // Hộp thoại xác nhận xóa (Có cảnh báo xóa thủ công)
  Future<bool> _showConfirmDialog(String email) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn đang xóa dữ liệu của giáo viên: $email\n\nLưu ý: App chỉ xóa hồ sơ. Bạn cần vào mục Authentication trên Firebase Console để xóa thủ công tài khoản này nếu muốn dùng lại email!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Chỉ xóa Hồ sơ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Hộp thoại Thêm/Sửa
  void _showTeacherDialog({String? uid, String? currentName}) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(uid == null ? "Thêm Giáo Viên Mới" : "Cập Nhật Tên"),
          content: _isProcessing
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Họ và tên"),
              ),
              if (uid == null) ...[
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email đăng nhập"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Mật khẩu (>= 6 ký tự)"),
                  obscureText: true,
                ),
              ],
            ],
          ),
          actions: _isProcessing ? [] : [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (uid == null) {
                  if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.length >= 6) {
                    _addTeacher(nameController.text, emailController.text, passwordController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin")));
                  }
                } else {
                  _db.collection('users').doc(uid).update({'name': nameController.text});
                  Navigator.pop(context);
                }
              },
              child: const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Giáo Viên"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Chưa có giáo viên nào."));
              }

              final teachers = snapshot.data!.docs;

              return ListView.builder(
                itemCount: teachers.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  var t = teachers[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showTeacherDialog(uid: t.id, currentName: t['name']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTeacher(t.id, t['email']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}