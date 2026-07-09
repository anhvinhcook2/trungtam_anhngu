import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleView extends StatelessWidget {
  final String? studentId;
  final String? teacherId;

  const ScheduleView({super.key, this.studentId, this.teacherId});

  @override
  Widget build(BuildContext context) {
    // Nếu không có studentId hay teacherId truyền vào, thử lấy từ Auth
    String? uid = studentId ?? teacherId;
    String? role = studentId != null ? 'student' : (teacherId != null ? 'teacher' : null);

    return Scaffold(
      appBar: AppBar(title: const Text("Thời khóa biểu")),
      body: _buildContent(context, uid, role),
    );
  }

  Widget _buildContent(BuildContext context, String? uid, String? role) {
    if (uid == null) return const Center(child: Text("Không đủ thông tin"));
    
    var classQuery = FirebaseFirestore.instance.collection('classes');
    Query query = role == 'teacher' 
        ? classQuery.where('teacherId', isEqualTo: uid)
        : classQuery.where('studentIds', arrayContains: uid);

    return FutureBuilder<QuerySnapshot>(
      future: query.get(),
      builder: (context, classSnap) {
        if (!classSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        List<String> classIds = classSnap.data!.docs.map((d) => d.id).toList();
        if (classIds.isEmpty) return const Center(child: Text("Không có lịch học."));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('schedules').where('classId', whereIn: classIds).snapshots(),
          builder: (context, scheduleSnap) {
            if (!scheduleSnap.hasData) return const Center(child: CircularProgressIndicator());
            
            var schedules = scheduleSnap.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                var s = schedules[index];
                String day = s['dayOfWeek'] == 1 ? "Chủ nhật" : "Thứ ${s['dayOfWeek']}";
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text("$day | ${s['startTime']} - ${s['endTime']}"),
                    subtitle: Text("Lớp: ${s['classId']}"), 
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
