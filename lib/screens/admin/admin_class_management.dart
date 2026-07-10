import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminClassManagement extends StatefulWidget {
  const AdminClassManagement({super.key});

  @override
  State<AdminClassManagement> createState() => _AdminClassManagementState();
}

class _AdminClassManagementState extends State<AdminClassManagement> {
  final _db = FirebaseFirestore.instance;

  // Kiểm tra trùng lịch (Giáo viên hoặc Phòng học)
  Future<bool> _isConflict(String teacherId, String room, DateTime date, String startTime, String endTime) async {
    final query = await _db.collection('schedules')
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .get();

    for (var doc in query.docs) {
      if (doc['startTime'] == startTime || doc['endTime'] == endTime) {
        var classDoc = await _db.collection('classes').doc(doc['classId']).get();
        if (classDoc.exists) {
          var classData = classDoc.data() as Map<String, dynamic>;
          if (classData['teacherId'] == teacherId || classData['room'] == room) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Kiểm tra học sinh có trùng môn hoặc trùng giờ không
  Future<String?> _checkStudentConflict(String studentId, String classId) async {
    var newClass = await _db.collection('classes').doc(classId).get();
    var newClassData = newClass.data() as Map<String, dynamic>;
    String newSubject = newClassData['subject'];
    var newSchedules = await _db.collection('schedules').where('classId', isEqualTo: classId).get();

    var studentClasses = await _db.collection('classes').where('studentIds', arrayContains: studentId).get();
    for (var doc in studentClasses.docs) {
      if (doc.id == classId) continue;
      var data = doc.data();
      if (data['subject'] == newSubject) return "Học sinh đã học môn ${data['subject']} trong lớp ${data['name']}";
      
      var schedules = await _db.collection('schedules').where('classId', isEqualTo: doc.id).get();
      for (var s in schedules.docs) {
        for (var ns in newSchedules.docs) {
          if (s['date'] == ns['date'] && s['startTime'] == ns['startTime']) return "Trùng thời gian học với lớp ${data['name']}";
        }
      }
    }
    return null;
  }

  void _showAddClassDialog() async {
    final nameC = TextEditingController();
    final subjectC = TextEditingController();
    int? selectedLevel;
    String? selectedTeacher;
    String? selectedRoom;
    DateTime? startDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    Set<int> selectedDays = {};
    final teachers = await _db.collection('users').where('role', isEqualTo: 'teacher').get();
    final rooms = ["Phòng 101", "Phòng 102", "Phòng 201", "Phòng 202", "Phòng 301"];

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Tạo Lớp Mới (2 tháng)"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: "Tên lớp")),
              TextField(controller: subjectC, decoration: const InputDecoration(labelText: "Tên môn học")),
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text("Chọn cấp độ (1-6)"),
                value: selectedLevel,
                onChanged: (v) => setDialogState(() => selectedLevel = v),
                items: List.generate(6, (i) => i + 1).map((l) => DropdownMenuItem(value: l, child: Text("Cấp độ $l"))).toList(),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Chọn giáo viên"),
                value: selectedTeacher,
                onChanged: (v) => setDialogState(() => selectedTeacher = v),
                items: teachers.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Chọn phòng học"),
                value: selectedRoom,
                onChanged: (v) => setDialogState(() => selectedRoom = v),
                items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              ),
              ListTile(
                title: Text(startDate == null ? "Chọn ngày bắt đầu" : "Bắt đầu: ${startDate!.day}/${startDate!.month}/${startDate!.year}"),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (d != null) setDialogState(() => startDate = d);
                },
              ),
              Row(children: [
                Expanded(child: ListTile(
                  title: Text(startTime == null ? "Giờ bắt đầu" : startTime!.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                    if (t != null) setDialogState(() => startTime = t);
                  },
                )),
                Expanded(child: ListTile(
                  title: Text(endTime == null ? "Giờ kết thúc" : endTime!.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
                    if (t != null) setDialogState(() => endTime = t);
                  },
                )),
              ]),
              const Text("Chọn 2 ngày học/tuần:"),
              Wrap(spacing: 8, children: List.generate(7, (i) {
                int day = i + 1;
                return FilterChip(
                  label: Text(day == 7 ? "CN" : "T${day + 1}"),
                  selected: selectedDays.contains(day),
                  onSelected: (bool selected) {
                    setDialogState(() {
                      if (selected) {
                        if (selectedDays.length < 2) selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                );
              })),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: () async {
              if (nameC.text.isNotEmpty && subjectC.text.isNotEmpty && selectedLevel != null && selectedTeacher != null && selectedRoom != null && startDate != null && startTime != null && endTime != null && selectedDays.length == 2) {
                // Kiểm tra trùng tên lớp
                var nameCheck = await _db.collection('classes').where('name', isEqualTo: nameC.text).get();
                if (nameCheck.docs.isNotEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tên lớp đã tồn tại!")));
                   return;
                }

                DateTime endDate = DateTime(startDate!.year, startDate!.month + 2, startDate!.day);
                String sTime = "${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}";
                String eTime = "${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}";

                bool hasConflict = false;
                for (DateTime d = startDate!; d.isBefore(endDate); d = d.add(const Duration(days: 1))) {
                  if (selectedDays.contains(d.weekday)) {
                    if (await _isConflict(selectedTeacher!, selectedRoom!, d, sTime, eTime)) {
                      hasConflict = true;
                      break;
                    }
                  }
                }
                if (hasConflict) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trùng lịch giáo viên hoặc phòng học!"), backgroundColor: Colors.red));
                  return;
                }

                var classRef = await _db.collection('classes').add({
                  'name': nameC.text,
                  'subject': subjectC.text,
                  'level': selectedLevel,
                  'teacherId': selectedTeacher,
                  'room': selectedRoom,
                  'studentIds': [],
                  'isActive': true,
                  'start_date': Timestamp.fromDate(startDate!),
                  'end_date': Timestamp.fromDate(endDate),
                });
                
                for (DateTime d = startDate!; d.isBefore(endDate); d = d.add(const Duration(days: 1))) {
                  if (selectedDays.contains(d.weekday)) {
                    await _db.collection('schedules').add({
                      'classId': classRef.id,
                      'dayOfWeek': d.weekday,
                      'date': Timestamp.fromDate(d),
                      'startTime': sTime,
                      'endTime': eTime,
                    });
                  }
                }
                
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
      var schedules = await _db.collection('schedules').where('classId', isEqualTo: classId).get();
      for (var doc in schedules.docs) await doc.reference.delete();
      await _db.collection('classes').doc(classId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa lớp học và lịch học liên quan!")));
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
                  onTap: () async {
                    if (!isSelected) {
                      String? error = await _checkStudentConflict(s.id, classId);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        return;
                      }
                      setDialogState(() => selected.add(s.id));
                    } else {
                      setDialogState(() => selected.remove(s.id));
                    }
                  },
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
              await _db.collection('classes').doc(classId).update({'studentIds': selected});
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
                    const SizedBox(height: 8),
                    Text("${doc['subject'] ?? 'N/A'} - Cấp độ ${doc['level'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("Phòng: ${doc['room'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54)),
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
                        Text("Sỹ số: ${doc['studentIds'].length} học viên", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () => _showClassDetails(doc.id, doc['name']),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(90, 40)),
                                  child: const Text("XEM", style: TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () => _manageStudents(doc.id, doc['studentIds']),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(90, 40)),
                                  child: const Text("QUẢN LÝ", style: TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
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

  void _showClassDetails(String classId, String className) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 3,
        child: AlertDialog(
          title: Text("Chi tiết lớp: $className"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                const TabBar(tabs: [
                  Tab(text: "Báo cáo nhanh"),
                  Tab(text: "Đánh giá HV"),
                  Tab(text: "Tổng hợp"),
                ], labelColor: Colors.black),
                Expanded(
                  child: TabBarView(children: [
                    _buildQuickReportsTab(classId),
                    _buildStudentEvaluationsTab(classId),
                    _buildClassSummaryTab(classId),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReportsTab(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports').where('class_id', isEqualTo: classId).where('type', isEqualTo: 'feedback').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var reports = snapshot.data!.docs;
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, i) {
            var r = reports[i];
            DateTime date = (r['timestamp'] as Timestamp).toDate();
            return ListTile(
              title: Text("${date.day}/${date.month}/${date.year}"),
              subtitle: Text(r['content']),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentEvaluationsTab(String classId) {
    return FutureBuilder<QuerySnapshot>(
      future: _db.collection('reports').where('class_id', isEqualTo: classId).where('type', isEqualTo: 'periodic').get(),
      builder: (context, reportSnapshot) {
        if (!reportSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        var reports = reportSnapshot.data!.docs;
        if (reports.isEmpty) return const Center(child: Text("Chưa có đánh giá"));

        // Lấy danh sách ID học sinh duy nhất để fetch data
        Set<String> studentIds = reports.map((r) => r['student_id'] as String).toSet();

        // Sắp xếp báo cáo theo thời gian giảm dần (mới nhất lên đầu)
        reports.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

        return FutureBuilder<QuerySnapshot>(
          future: _db.collection('users').where(FieldPath.documentId, whereIn: studentIds.toList()).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            // Map để tra cứu nhanh thông tin học sinh
            Map<String, DocumentSnapshot> userMap = {for (var doc in userSnapshot.data!.docs) doc.id: doc};

            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, i) {
                var r = reports[i];
                var u = userMap[r['student_id']];
                Map<String, dynamic> uData = u?.data() as Map<String, dynamic>? ?? {};
                String name = uData['name'] ?? "Unknown";
                String code = uData['studentCode'] ?? uData['student_code'] ?? '';
                
                // Kiểm tra trùng tên
                bool hasDuplicateName = reports.where((rep) {
                  var otherU = userMap[rep['student_id']];
                  return (otherU?.data() as Map<String, dynamic>?)?['name'] == name;
                }).length > 1;
                String displayTitle = hasDuplicateName ? "$name ($code)" : name;

                return ListTile(
                  title: Text(displayTitle),
                  subtitle: Text("Điểm: ${r['scores']}"),
                  trailing: Text("${(r['timestamp'] as Timestamp).toDate().day}/${(r['timestamp'] as Timestamp).toDate().month}/${(r['timestamp'] as Timestamp).toDate().year}"),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildClassSummaryTab(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports').where('class_id', isEqualTo: classId).where('type', isEqualTo: 'periodic').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var reports = snapshot.data!.docs;
        if (reports.isEmpty) return const Center(child: Text("Chưa có đánh giá"));

        double sum = 0;
        double maxScore = 0;
        double minScore = 10;
        for (var r in reports) {
          double score = (r['scores'] as num).toDouble();
          sum += score;
          if (score > maxScore) maxScore = score;
          if (score < minScore) minScore = score;
        }
        double avg = sum / reports.length;

        return Column(
          children: [
            ListTile(title: Text("Điểm TB: ${avg.toStringAsFixed(1)}")),
            ListTile(title: Text("Điểm cao nhất: $maxScore")),
            ListTile(title: Text("Điểm thấp nhất: $minScore")),
          ],
        );
      },
    );
  }
}
