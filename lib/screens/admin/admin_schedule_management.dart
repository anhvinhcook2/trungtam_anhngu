import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScheduleManagement extends StatefulWidget {
  const AdminScheduleManagement({super.key});

  @override
  State<AdminScheduleManagement> createState() => _AdminScheduleManagementState();
}

class _AdminScheduleManagementState extends State<AdminScheduleManagement> {
  final _db = FirebaseFirestore.instance;
  final List<String> _rooms = ["Phòng 101", "Phòng 102", "Phòng 201", "Phòng 202", "Phòng 301"];

  static DateTime _getStartOfWeek(DateTime date) {
    DateTime start = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  int _selectedYear = DateTime.now().year;
  DateTime? _selectedWeekStart;
  List<DateTime> _availableWeeks = [];

  @override
  void initState() {
    super.initState();
    _selectCurrentWeek();
  }

  void _generateWeeksForYear(int year) {
    List<DateTime> weeks = [];
    DateTime firstDay = DateTime(year, 1, 1);
    DateTime firstMonday = firstDay.add(Duration(days: (8 - firstDay.weekday) % 7));
    
    DateTime currentWeek = firstMonday;
    while (currentWeek.year == year) {
      weeks.add(currentWeek);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }
    
    setState(() {
      _availableWeeks = weeks;
    });
  }

  void _selectCurrentWeek() {
    DateTime now = DateTime.now();
    DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime currentWeek = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
    
    setState(() {
      _selectedYear = currentWeek.year;
      _generateWeeksForYear(_selectedYear);
      if (_availableWeeks.contains(currentWeek)) {
        _selectedWeekStart = currentWeek;
      } else {
        _selectedWeekStart = _availableWeeks.isNotEmpty ? _availableWeeks.first : null;
      }
    });
  }

  Future<bool> _isConflict(String classId, String newRoom, DateTime date, String startTime, String endTime, {String? excludeId}) async {
    var currentClassDoc = await _db.collection('classes').doc(classId).get();
    var currentClassData = currentClassDoc.data() as Map<String, dynamic>;
    String currentTeacherId = currentClassData['teacherId'];

    final query = await _db.collection('schedules')
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .get();

    for (var doc in query.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      bool timeOverlap = doc['startTime'] == startTime || doc['endTime'] == endTime;
      if (timeOverlap) {
        var classDoc = await _db.collection('classes').doc(doc['classId']).get();
        if (classDoc.exists) {
          var classData = classDoc.data() as Map<String, dynamic>;
          if (classData['room'] == newRoom || classData['teacherId'] == currentTeacherId) return true;
        }
      }
    }
    return false;
  }

  void _showScheduleDialog({DocumentSnapshot? schedule}) async {
    final classes = await _db.collection('classes').get();
    String? selectedClass = schedule?['classId'];

    var classDoc = selectedClass != null ? await _db.collection('classes').doc(selectedClass).get() : null;
    String? currentRoom = classDoc?.exists == true ? (classDoc!.data() as Map<String, dynamic>)['room'] : _rooms.first;

    DateTime date = schedule != null ? (schedule['date'] as Timestamp).toDate() : (_selectedWeekStart ?? DateTime.now());
    TimeOfDay startTime = schedule != null
        ? TimeOfDay(hour: int.parse(schedule['startTime'].split(':')[0]), minute: int.parse(schedule['startTime'].split(':')[1]))
        : const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = schedule != null
        ? TimeOfDay(hour: int.parse(schedule['endTime'].split(':')[0]), minute: int.parse(schedule['endTime'].split(':')[1]))
        : const TimeOfDay(hour: 20, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(schedule == null ? "Tạo Lịch Học" : "Sửa Lịch Học"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Chọn lớp"),
                value: selectedClass,
                onChanged: (v) async {
                  var classDoc = await _db.collection('classes').doc(v).get();
                  setDialogState(() {
                    selectedClass = v;
                    currentRoom = (classDoc.data() as Map<String, dynamic>)['room'];
                  });
                },
                items: classes.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Chọn phòng học"),
                value: currentRoom,
                onChanged: (v) => setDialogState(() => currentRoom = v),
                items: _rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              ),
              ListTile(
                title: Text("Ngày: ${date.day}/${date.month}/${date.year}"),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(_selectedYear), lastDate: DateTime(_selectedYear, 12, 31));
                  if (d != null) setDialogState(() => date = d);
                },
              ),
              Row(children: [
                Expanded(child: ListTile(
                  title: Text("BĐ: ${startTime.format(context)}"),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: startTime);
                    if (t != null) setDialogState(() => startTime = t);
                  },
                )),
                Expanded(child: ListTile(
                  title: Text("KT: ${endTime.format(context)}"),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: endTime);
                    if (t != null) setDialogState(() => endTime = t);
                  },
                )),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: () async {
              if (selectedClass != null && currentRoom != null) {
                String sTime = "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}";
                String eTime = "${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}";

                if (await _isConflict(selectedClass!, currentRoom!, date, sTime, eTime, excludeId: schedule?.id)) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trùng lịch!"), backgroundColor: Colors.red));
                  return;
                }

                await _db.collection('classes').doc(selectedClass).update({'room': currentRoom});
                if (schedule == null) {
                  await _db.collection('schedules').add({'classId': selectedClass, 'dayOfWeek': date.weekday, 'date': Timestamp.fromDate(date), 'startTime': sTime, 'endTime': eTime});
                } else {
                  await schedule.reference.update({'date': Timestamp.fromDate(date), 'dayOfWeek': date.weekday, 'startTime': sTime, 'endTime': eTime});
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            }, child: const Text("Lưu")),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("Quản lý TKB", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [_buildYearAndWeekPicker(), Expanded(child: _buildScheduleGrid())]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Thêm lịch"),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildYearAndWeekPicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        DropdownButton<int>(
          value: _selectedYear,
          items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(),
          onChanged: (y) {
            if (y != null) {
              setState(() {
                _selectedYear = y;
                _generateWeeksForYear(y);
                _selectedWeekStart = _availableWeeks.isNotEmpty ? _availableWeeks.first : null;
              });
            }
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DateTime>(
              isExpanded: true,
              value: _selectedWeekStart,
              onChanged: (DateTime? newValue) {
                if (newValue != null) setState(() => _selectedWeekStart = newValue);
              },
              items: _availableWeeks.map((DateTime weekStart) {
                DateTime weekEnd = weekStart.add(const Duration(days: 6));
                return DropdownMenuItem<DateTime>(
                  value: weekStart,
                  child: Text("Tuần: ${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}"),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildScheduleGrid() {
    if (_selectedWeekStart == null) return const Center(child: Text("Chọn tuần"));
    DateTime weekEnd = _selectedWeekStart!.add(const Duration(days: 7));
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('schedules')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedWeekStart!))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var schedules = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 7,
          itemBuilder: (context, i) {
            int day = i + 1;
            var daySchedules = schedules.where((s) => s['dayOfWeek'] == day).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(day == 7 ? "Chủ Nhật" : "Thứ ${day + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
              ...daySchedules.map((s) => FutureBuilder<DocumentSnapshot>(
                future: _db.collection('classes').doc(s['classId']).get(),
                builder: (context, cSnap) {
                  Map<String, dynamic> cData = (cSnap.hasData && cSnap.data!.exists) ? cSnap.data!.data() as Map<String, dynamic> : {};
                  return Card(
                    child: ListTile(
                      title: Text("${s['startTime']} - ${s['endTime']}"),
                      subtitle: Text("Phòng: ${cData['room'] ?? '...'} | Lớp: ${cData['name'] ?? '...'} (${cData['subject'] ?? '...'})"),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showScheduleDialog(schedule: s)),
                        IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => s.reference.delete()),
                      ]),
                    ),
                  );
                }
              )),
            ]);
          },
        );
      },
    );
  }
}
