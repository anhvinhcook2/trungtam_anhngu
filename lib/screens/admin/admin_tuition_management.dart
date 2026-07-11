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

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final String _fontFamily = 'Nunito';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Quản Lý Học Phí", 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900, fontSize: 18, color: _primaryColor, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dropdown chọn lớp (Thiết kế lại thành khối bo tròn hiện đại)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              "Chọn lớp học để kiểm tra", 
              style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('classes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Chưa có lớp học nào.", style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent)),
                );
              }
              
              var classes = snapshot.data!.docs;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Bo góc 16px
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Nhấn để chọn lớp", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 15)),
                    value: _selectedClassId,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                    onChanged: (v) => setState(() => _selectedClassId = v),
                    items: classes.map((c) => DropdownMenuItem(
                      value: c.id, 
                      child: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                    )).toList(),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),

          // 2. Danh sách học viên và trạng thái học phí
          if (_selectedClassId == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
                      child: Icon(Icons.payments_outlined, size: 64, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 16),
                    Text("Vui lòng chọn lớp học phía trên", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _db.collection('classes').doc(_selectedClassId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _primaryColor));
                  
                  var doc = snapshot.data!;
                  if (!doc.exists) return Center(child: Text("Lớp không tồn tại", style: TextStyle(fontFamily: _fontFamily)));

                  var data = doc.data() as Map<String, dynamic>;
                  List<String> studentIds = List<String>.from(data['studentIds'] ?? []);

                  if (studentIds.isEmpty) {
                    return Center(
                      child: Text("Lớp này chưa có học viên nào.", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 15)),
                    );
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: _db.collection('users').where(FieldPath.documentId, whereIn: studentIds).get(),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _primaryColor));
                      
                      var students = studentSnapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: students.length,
                        itemBuilder: (context, i) {
                          var s = students[i];
                          String studentId = s.id;
                          String month = DateTime.now().toString().substring(0, 7);

                          // StreamBuilder lồng để cập nhật trạng thái học phí thời gian thực
                          return StreamBuilder<QuerySnapshot>(
                            stream: _db.collection('tuition')
                                .where('studentId', isEqualTo: studentId)
                                .where('classId', isEqualTo: _selectedClassId)
                                .where('month', isEqualTo: month)
                                .snapshots(),
                            builder: (context, tuitionSnap) {
                              bool isPaid = false;
                              if (tuitionSnap.hasData && tuitionSnap.data!.docs.isNotEmpty) {
                                isPaid = tuitionSnap.data!.docs.first['status'] == 'paid';
                              }

                              // Cấu hình màu sắc theo trạng thái
                              Color statusColor = isPaid ? const Color(0xFF10B981) : Colors.red.shade500;
                              Color statusBgColor = isPaid ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.shade50;
                              String statusText = isPaid ? "Đã đóng ($month)" : "Chưa đóng học phí";
                              IconData statusIcon = isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                  border: Border.all(color: isPaid ? Colors.green.withOpacity(0.3) : Colors.transparent, width: 1),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: _primaryColor.withOpacity(0.1),
                                    child: Text(
                                      s['name'][0].toUpperCase(),
                                      style: TextStyle(fontFamily: _fontFamily, color: _primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    s['name'], 
                                    style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBgColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(fontFamily: _fontFamily, color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  trailing: InkWell(
                                    onTap: () => _updateTuition(studentId, _selectedClassId!),
                                    borderRadius: BorderRadius.circular(50),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(statusIcon, color: statusColor, size: 28),
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