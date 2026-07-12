import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminClassManagement extends StatefulWidget {
  const AdminClassManagement({super.key});

  @override
  State<AdminClassManagement> createState() => _AdminClassManagementState();
}

class _AdminClassManagementState extends State<AdminClassManagement> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = "Tất cả";

  static const Color primary = Color(0xFF003331);
  static const Color accent = Color(0xFFFEA520);

  // ==================== LOGIC DỮ LIỆU (Giữ nguyên gốc) ====================

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
          if (s['date'] == ns['date'] && s['startTime'] == ns['startTime']) {
            return "Trùng thời gian học với lớp ${data['name']}";
          }
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
                contentPadding: EdgeInsets.zero,
                title: Text(startDate == null ? "Chọn ngày bắt đầu" : "Bắt đầu: ${startDate!.day}/${startDate!.month}/${startDate!.year}"),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (d != null) setDialogState(() => startDate = d);
                },
              ),
              Row(children: [
                Expanded(child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startTime == null ? "Giờ bắt đầu" : startTime!.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                    if (t != null) setDialogState(() => startTime = t);
                  },
                )),
                Expanded(child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(endTime == null ? "Giờ kết thúc" : endTime!.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
                    if (t != null) setDialogState(() => endTime = t);
                  },
                )),
              ]),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text("Chọn 2 ngày học/tuần:", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
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
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameC.text.isNotEmpty && subjectC.text.isNotEmpty && selectedLevel != null && selectedTeacher != null && selectedRoom != null && startDate != null && startTime != null && endTime != null && selectedDays.length == 2) {
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
        content: Text("Bạn có chắc muốn xóa lớp học '$className'?"),
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

  // Tối ưu UI quản lý học sinh (ListView thay cho GridView)
  void _manageStudents(String classId, List currentList) async {
    final students = await _db.collection('users').where('role', isEqualTo: 'student').get();
    List selected = List.from(currentList);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Gán Sỹ Số", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.only(top: 16),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Fixed height for scrollable list
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: students.docs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                var s = students.docs[i];
                bool isSelected = selected.contains(s.id);
                return CheckboxListTile(
                  activeColor: primary,
                  title: Text(s['name'], style: const TextStyle(fontSize: 15)),
                  value: isSelected,
                  onChanged: (bool? checked) async {
                    if (checked == true) {
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
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                onPressed: () async {
                  await _db.collection('classes').doc(classId).update({'studentIds': selected});
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("CẬP NHẬT")
            ),
          ],
        );
      }),
    );
  }

  void _showClassDetails(String classId, String className) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 3,
        child: AlertDialog(
          titlePadding: const EdgeInsets.all(16),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Chi tiết: $className", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              children: [
                const TabBar(
                  labelPadding: EdgeInsets.zero,
                  indicatorColor: primary,
                  labelColor: primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Báo cáo"),
                    Tab(text: "Đánh giá"),
                    Tab(text: "Tổng hợp"),
                  ],
                ),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))
          ],
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
        if (reports.isEmpty) return const Center(child: Text("Chưa có báo cáo nào"));
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            var r = reports[i];
            DateTime date = (r['timestamp'] as Timestamp).toDate();
            return ListTile(
              title: Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

        Set<String> studentIds = reports.map((r) => r['student_id'] as String).toSet();
        reports.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

        return FutureBuilder<QuerySnapshot>(
          future: _db.collection('users').where(FieldPath.documentId, whereIn: studentIds.toList()).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            Map<String, DocumentSnapshot> userMap = {for (var doc in userSnapshot.data!.docs) doc.id: doc};

            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                var r = reports[i];
                var u = userMap[r['student_id']];
                Map<String, dynamic> uData = u?.data() as Map<String, dynamic>? ?? {};
                String name = uData['name'] ?? "Unknown";
                String code = uData['studentCode'] ?? uData['student_code'] ?? '';

                bool hasDuplicateName = reports.where((rep) {
                  var otherU = userMap[rep['student_id']];
                  return (otherU?.data() as Map<String, dynamic>?)?['name'] == name;
                }).length > 1;
                String displayTitle = hasDuplicateName ? "$name ($code)" : name;

                return ListTile(
                  title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Điểm: ${r['scores']}", style: const TextStyle(color: Colors.redAccent)),
                  trailing: Text("${(r['timestamp'] as Timestamp).toDate().day}/${(r['timestamp'] as Timestamp).toDate().month}/${(r['timestamp'] as Timestamp).toDate().year}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        if (reports.isEmpty) return const Center(child: Text("Chưa có dữ liệu tổng hợp"));

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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryRow("Điểm Trung Bình", avg.toStringAsFixed(1), Colors.blue),
            const Divider(),
            _buildSummaryRow("Điểm Cao Nhất", maxScore.toString(), Colors.green),
            const Divider(),
            _buildSummaryRow("Điểm Thấp Nhất", minScore.toString(), Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ==================== GIAO DIỆN MOBILE CHUẨN ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text("Quản lý Lớp học", style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 18)),
        iconTheme: const IconThemeData(color: primary),
      ),
      // Chuyển nút Thêm sang FAB cho chuẩn Mobile
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        backgroundColor: accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Giới thiệu
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text("Theo dõi và quản lý danh sách các khóa đào tạo hiện có.",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Tìm tên lớp, mã lớp...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: "Tất cả", child: Text("Tất cả trạng thái", style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: "Đang học", child: Text("Đang học", style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: "Sắp khai giảng", child: Text("Sắp khai giảng", style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (val) => setState(() => _statusFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                              _statusFilter = "Tất cả";
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Class List (Chuyển sang ListView thay vì GridView)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final id = doc.id.toLowerCase();
                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || id.contains(_searchQuery);

                  final isActive = data['isActive'] == true;
                  final matchesStatus = _statusFilter == "Tất cả" ||
                      (_statusFilter == "Đang học" && isActive) ||
                      (_statusFilter == "Sắp khai giảng" && !isActive);

                  return matchesSearch && matchesStatus;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Không tìm thấy lớp học", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding dưới để không che bởi FAB
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildClassCardMobile(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Card ngang tối ưu cho Mobile
  Widget _buildClassCardMobile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String status = data['isActive'] == true ? "Đang học" : "Sắp khai giảng";
    final Color statusColor = data['isActive'] == true ? Colors.green : Colors.orange;
    final int studentCount = (data['studentIds'] as List?)?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Icon, Tên lớp, Trạng thái
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF004B49).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Color(0xFF004B49), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mã lớp: ${doc.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(data['name'] ?? "Không có tên", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot>(
                        future: _db.collection('users').doc(data['teacherId']).get(),
                        builder: (context, snap) {
                          return Text(
                            "GV: ${snap.hasData && snap.data!.exists ? snap.data!['name'] : 'Đang tải...'}",
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Stats section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItemMobile("Sĩ số", "$studentCount", Icons.people_outline),
                _buildStatItemMobile("Cấp độ", "${data['level'] ?? '-'}", Icons.trending_up),
                _buildStatItemMobile("Phòng", "${data['room'] ?? '-'}", Icons.meeting_room_outlined),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Buttons section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClassDetails(doc.id, data['name'] ?? ''),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text("Chi tiết"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageStudents(doc.id, data['studentIds'] ?? []),
                    icon: const Icon(Icons.manage_accounts, size: 18),
                    label: const Text("Sỹ số"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteClass(doc.id, data['name'] ?? ''),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: "Xóa lớp",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemMobile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary)),
          ],
        ),
      ],
    );
  }
}
