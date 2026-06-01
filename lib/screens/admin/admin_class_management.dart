import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminClassManagement extends StatefulWidget {
  const AdminClassManagement({super.key});

  @override
  State<AdminClassManagement> createState() => _AdminClassManagementState();
}

class _AdminClassManagementState extends State<AdminClassManagement> {
  final _db = FirebaseFirestore.instance;

  void _showAddClassDialog() async {
    final nameC = TextEditingController();
    String? selectedTeacher;
    final teachers = await _db.collection('users').where('role', isEqualTo: 'teacher').get();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Tạo Lớp Mới"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Tên lớp")),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Chọn giáo viên"),
              value: selectedTeacher,
              onChanged: (v) => setDialogState(() => selectedTeacher = v),
              items: teachers.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: () async {
              if (nameC.text.isNotEmpty && selectedTeacher != null) {
                await _db.collection('classes').add({'name': nameC.text, 'teacherId': selectedTeacher, 'studentList': []});
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            }, child: const Text("Tạo")),
          ],
        );
      }),
    );
  }

  Future<void> _deleteClass(String classId, String className) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text("Xóa lớp học '$className'?"),
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
      await _db.collection('classes').doc(classId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa lớp học!")));
    }
  }

  void _manageStudents(String classId, List currentList) async {
    final students = await _db.collection('users').where('role', isEqualTo: 'student').get();
    List selected = List.from(currentList);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Gán Sỹ Số Lớp Học", style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5),
              itemCount: students.docs.length,
              itemBuilder: (context, i) {
                var s = students.docs[i];
                bool isSelected = selected.contains(s.id);
                return InkWell(
                  onTap: () => setDialogState(() => isSelected ? selected.remove(s.id) : selected.add(s.id)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: 2),
                    ),
                    child: Center(child: Text(s['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () async {
              await _db.collection('classes').doc(classId).update({'studentList': selected});
              if (context.mounted) Navigator.pop(context);
            }, child: const Text("XÁC NHẬN CẬP NHẬT")),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản Lý Lớp Học")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 15)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(doc['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteClass(doc.id, doc['name']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<DocumentSnapshot>(
                      future: _db.collection('users').doc(doc['teacherId']).get(),
                      builder: (context, tSnap) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(30)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(tSnap.hasData && tSnap.data!.exists ? "GV: ${tSnap.data!['name']}" : "Đang tải...", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                    ),
                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Sỹ số: ${doc['studentList'].length} học viên", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ElevatedButton(
                          onPressed: () => _manageStudents(doc.id, doc['studentList']),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(120, 40)),
                          child: const Text("QUẢN LÝ", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showAddClassDialog, label: const Text("THÊM LỚP MỚI"), icon: const Icon(Icons.add)),
    );
  }
}
