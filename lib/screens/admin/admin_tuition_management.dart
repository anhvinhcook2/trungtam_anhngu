import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTuitionManagement extends StatefulWidget {
  const AdminTuitionManagement({super.key});

  @override
  State<AdminTuitionManagement> createState() => _AdminTuitionManagementState();
}

class _AdminTuitionManagementState extends State<AdminTuitionManagement> {
  final _db = FirebaseFirestore.instance;
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý học phí")),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('classes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              var classes = snapshot.data!.docs;
              return DropdownButton<String>(
                hint: const Text("Chọn lớp"),
                value: _selectedClassId,
                onChanged: (v) => setState(() => _selectedClassId = v),
                items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c['name']))).toList(),
              );
            },
          ),
          if (_selectedClassId != null)
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _db.collection('classes').doc(_selectedClassId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  var doc = snapshot.data!;
                  if (!doc.exists) return const Text("Lớp không tồn tại");
                  
                  var data = doc.data() as Map<String, dynamic>;
                  List<String> studentIds = List<String>.from(data['studentIds'] ?? []);
                  
                  if (studentIds.isEmpty) return const Text("Lớp chưa có học viên");

                  return FutureBuilder<QuerySnapshot>(
                    future: _db.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
                    builder: (context, studentSnapshot) {
                      if (!studentSnapshot.hasData) return const CircularProgressIndicator();
                      var students = studentSnapshot.data!.docs;
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, i) {
                          var s = students[i];
                          return ListTile(
                            title: Text(s['name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.payment),
                              onPressed: () => _updateTuition(s.id, _selectedClassId!),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _updateTuition(String studentId, String classId) async {
    String month = DateTime.now().toString().substring(0, 7);
    var doc = await _db.collection('tuition')
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .where('month', isEqualTo: month)
        .get();
    
    if (doc.docs.isEmpty) {
      await _db.collection('tuition').add({
        'studentId': studentId,
        'classId': classId,
        'month': month,
        'status': 'paid',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      String newStatus = doc.docs.first['status'] == 'paid' ? 'pending' : 'paid';
      await _db.collection('tuition').doc(doc.docs.first.id).update({'status': newStatus});
    }
  }
}
