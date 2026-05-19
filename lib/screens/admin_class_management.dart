import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isProcessing = false;

  /// HÀM 1: TẠO LỚP HỌC MỚI VÀ GÁN GIÁO VIÊN
  Future<void> _addClass(String className, String teacherId, String teacherName) async {
    setState(() => _isProcessing = true);
    try {
      await _db.collection('classes').add({
        'name': className,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'student_ids': [], // Mặc định ban đầu chưa có học viên
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo lớp học thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// HÀM 2: XÓA LỚP HỌC
  Future<void> _deleteClass(String classId, String className) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa lớp '$className'? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.collection('classes').doc(classId).delete();
    }
  }

  /// DIALOG: NHẬP THÔNG TIN TẠO LỚP
  void _showAddClassDialog() {
    final nameController = TextEditingController();
    String? selectedTeacherId;
    String? selectedTeacherName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tạo Lớp Học Mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên lớp (VD: IELTS Basic)"),
              ),
              const SizedBox(height: 20),
              // Truy vấn danh sách Giáo viên trực tiếp trong Dialog
              FutureBuilder<QuerySnapshot>(
                future: _db.collection('users').where('role', isEqualTo: 'teacher').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("Chưa có giáo viên nào trong hệ thống.", style: TextStyle(color: Colors.red));
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Chọn Giáo viên phụ trách"),
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedTeacherId = val;
                        selectedTeacherName = snapshot.data!.docs.firstWhere((doc) => doc.id == val)['name'];
                      });
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedTeacherId != null) {
                  Navigator.pop(context);
                  _addClass(nameController.text, selectedTeacherId!, selectedTeacherName!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng nhập tên lớp và chọn giáo viên.")),
                  );
                }
              },
              child: const Text("Tạo Lớp"),
            ),
          ],
        ),
      ),
    );
  }

  /// DIALOG: GÁN HỌC VIÊN VÀO LỚP
  void _showManageStudentsDialog(String classId, String className, List<dynamic> currentStudentIds) {
    // Tạo một bản sao danh sách ID học viên hiện tại của lớp để thao tác checkbox
    List<String> tempSelectedIds = List<String>.from(currentStudentIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Danh sách Học viên\nLớp: $className"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Chiều cao cố định để list có thể cuộn được
            child: FutureBuilder<QuerySnapshot>(
              future: _db.collection('users').where('role', isEqualTo: 'student').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có học viên nào trong hệ thống."));

                final students = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    bool isSelected = tempSelectedIds.contains(student.id);

                    return CheckboxListTile(
                      title: Text("${student['name']} - ${student['student_code']}"),
                      subtitle: Text(student['email']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedIds.add(student.id);
                          } else {
                            tempSelectedIds.remove(student.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                setState(() => _isProcessing = true);
                Navigator.pop(context);

                // Cập nhật lại mảng student_ids lên Firestore
                await _db.collection('classes').doc(classId).update({
                  'student_ids': tempSelectedIds,
                });

                setState(() => _isProcessing = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật danh sách học viên!"), backgroundColor: Colors.green));
                }
              },
              child: const Text("Lưu thay đổi"),
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
        title: const Text("Quản Lý Lớp Học"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('classes').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có lớp học nào."));

              final classes = snapshot.data!.docs;

              return ListView.builder(
                itemCount: classes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  var c = classes[index];
                  List<dynamic> studentIds = c['student_ids'] ?? [];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.class_, color: Colors.white)),
                            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text("Giáo viên: ${c['teacher_name']}\nSĩ số: ${studentIds.length} học viên"),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteClass(c.id, c['name']),
                            ),
                          ),
                          const Divider(),
                          TextButton.icon(
                            onPressed: () => _showManageStudentsDialog(c.id, c['name'], studentIds),
                            icon: const Icon(Icons.group_add, color: Colors.indigo),
                            label: const Text("Thêm/Bớt Học viên", style: TextStyle(color: Colors.indigo)),
                          )
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
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}