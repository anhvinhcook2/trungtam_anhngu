import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isProcessing = false;

  /// HÀM THÊM HỌC VIÊN: Tự động sinh Mã số học viên và Trạng thái học phí
  Future<void> _addStudent(String name, String email, String password) async {
    setState(() => _isProcessing = true);

    String tempAppName = "StudentApp_${DateTime.now().millisecondsSinceEpoch}";
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

      // Tự động tạo mã học viên (Ví dụ: HV + 6 số ngẫu nhiên từ thời gian)
      String studentCode = "HV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'name': name,
        'email': email,
        'role': 'student',
        'student_code': studentCode, // Mã số để phụ huynh tra cứu
        'tuition_status': 'Chưa đóng', // Trạng thái học phí mặc định
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thêm học viên thành công! Mã số: $studentCode"), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi: ${e.message}";
      if (e.code == 'email-already-in-use') {
        msg = "Email này vẫn còn trong hệ thống Auth. Hãy vào Firebase Console để xóa thủ công!";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e"), backgroundColor: Colors.red));
    } finally {
      await tempApp?.delete();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// HÀM XÓA THỦ CÔNG HỌC VIÊN
  Future<void> _deleteStudent(String uid, String name, String studentCode) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn đang xóa hồ sơ của học viên: $name ($studentCode).\n\nLưu ý: Bạn cần vào Authentication trên Firebase Console để xóa thủ công email đăng nhập nếu muốn dùng lại!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa Hồ sơ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isProcessing = true);
      try {
        await _db.collection('users').doc(uid).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa hồ sơ học viên thành công!"), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // Hàm Cập nhật trạng thái Học phí
  Future<void> _toggleTuitionStatus(String uid, String currentStatus) async {
    String newStatus = currentStatus == 'Chưa đóng' ? 'Đã đóng' : 'Chưa đóng';
    await _db.collection('users').doc(uid).update({'tuition_status': newStatus});
  }

  void _showStudentDialog({String? uid, String? currentName}) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(uid == null ? "Thêm Học Viên Mới" : "Cập Nhật Tên"),
          content: _isProcessing
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Họ và tên học viên")),
              if (uid == null) ...[
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email liên hệ")),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Mật khẩu (>= 6 ký tự)"), obscureText: true),
              ],
            ],
          ),
          actions: _isProcessing ? [] : [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (uid == null) {
                  if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.length >= 6) {
                    _addStudent(nameController.text, emailController.text, passwordController.text);
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
        title: const Text("Quản Lý Học Viên"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').where('role', isEqualTo: 'student').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có học viên nào."));

              final students = snapshot.data!.docs;

              return ListView.builder(
                itemCount: students.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  var s = students[index];
                  bool isPaid = s['tuition_status'] == 'Đã đóng';

                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.school, color: Colors.white)),
                      title: Text("${s['name']} - ${s['student_code']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['email']),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _toggleTuitionStatus(s.id, s['tuition_status']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Học phí: ${s['tuition_status']}",
                                style: TextStyle(color: isPaid ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showStudentDialog(uid: s.id, currentName: s['name'])),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStudent(s.id, s['name'], s['student_code'])),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}