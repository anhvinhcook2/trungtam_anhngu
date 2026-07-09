import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScheduleManagement extends StatefulWidget {
  const AdminScheduleManagement({super.key});

  @override
  State<AdminScheduleManagement> createState() => _AdminScheduleManagementState();
}

class _AdminScheduleManagementState extends State<AdminScheduleManagement> {
  final _db = FirebaseFirestore.instance;

  void _showAddScheduleDialog() async {
    final classes = await _db.collection('classes').get();
    String? selectedClass;
    int? dayOfWeek;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Tạo Lịch Học"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Chọn lớp"),
                value: selectedClass,
                onChanged: (v) => setDialogState(() => selectedClass = v),
                items: classes.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
              ),
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text("Chọn thứ"),
                value: dayOfWeek,
                onChanged: (v) => setDialogState(() => dayOfWeek = v),
                items: [2, 3, 4, 5, 6, 7, 1].map((d) => DropdownMenuItem(value: d, child: Text(d == 1 ? "Chủ nhật" : "Thứ $d"))).toList(),
              ),
              ListTile(
                title: Text(startTime == null ? "Giờ bắt đầu" : "Bắt đầu: ${startTime!.format(context)}"),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) setDialogState(() => startTime = t);
                },
              ),
              ListTile(
                title: Text(endTime == null ? "Giờ kết thúc" : "Kết thúc: ${endTime!.format(context)}"),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) setDialogState(() => endTime = t);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: () async {
              if (selectedClass != null && dayOfWeek != null && startTime != null && endTime != null) {
                await _db.collection('schedules').add({
                  'classId': selectedClass,
                  'dayOfWeek': dayOfWeek,
                  'startTime': "${startTime!.hour}:${startTime!.minute}",
                  'endTime': "${endTime!.hour}:${endTime!.minute}",
                });
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
      appBar: AppBar(title: const Text("Quản lý Thời khóa biểu")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('schedules').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text("Thứ ${doc['dayOfWeek']} | ${doc['startTime']} - ${doc['endTime']}"),
                subtitle: Text("Lớp: ${doc['classId']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _db.collection('schedules').doc(doc.id).delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddScheduleDialog, child: const Icon(Icons.add)),
    );
  }
}
