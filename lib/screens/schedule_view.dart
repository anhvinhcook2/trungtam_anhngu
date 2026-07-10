import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleView extends StatefulWidget {
  final String? studentId;
  final String? teacherId;

  const ScheduleView({super.key, this.studentId, this.teacherId});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  DateTime _selectedWeekStart = _getStartOfWeek(DateTime.now());

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    String? uid = widget.studentId ?? widget.teacherId;
    String role = widget.studentId != null ? 'student' : 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Thời Khóa Biểu", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('classes')
            .where(role == 'teacher' ? 'teacherId' : 'studentIds', 
                   isEqualTo: role == 'teacher' ? uid : null,
                   arrayContains: role == 'student' ? uid : null)
            .get(),
        builder: (context, classSnap) {
          if (!classSnap.hasData) return const Center(child: CircularProgressIndicator());
          
          List<String> myClassIds = classSnap.data!.docs.map((d) => d.id).toList();
          Map<String, String> classRooms = {};
          for (var doc in classSnap.data!.docs) {
            classRooms[doc.id] = (doc.data() as Map<String, dynamic>)['room'] ?? 'N/A';
          }

          if (myClassIds.isEmpty) return const Center(child: Text("Không có lịch."));

          return Column(
            children: [
              _buildWeekPicker(myClassIds),
              Expanded(child: _buildScheduleGrid(myClassIds, classRooms)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekPicker(List<String> classIds) {
    // Logic này sẽ cần cải thiện để lấy range từ schedules của các classIds
    // Tạm thời hiển thị danh sách tuần cố định để đảm bảo UI hoạt động
    return Container(
      height: 80,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          DateTime weekStart = _getStartOfWeek(DateTime.now().add(Duration(days: index * 7 - 35)));
          DateTime weekEnd = weekStart.add(const Duration(days: 6));
          bool isSelected = weekStart.isAtSameMomentAs(_selectedWeekStart);

          return GestureDetector(
            onTap: () => setState(() => _selectedWeekStart = weekStart),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}",
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleGrid(List<String> classIds, Map<String, String> classRooms) {
    DateTime weekEnd = _selectedWeekStart.add(const Duration(days: 7));
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schedules')
          .where('classId', whereIn: classIds)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedWeekStart))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Thêm dòng này để BẮT LỖI
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }

        // 2. Đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 3. Nếu không có dữ liệu
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có lịch trong tuần này.'));
        }
        var schedules = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 7,
          itemBuilder: (context, i) {
            int day = i + 1;
            var daySchedules = schedules.where((s) => s['dayOfWeek'] == day).toList();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70, 
                    child: Text(day == 7 ? "CN" : "Thứ ${day + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Expanded(
                    child: Column(
                      children: daySchedules.map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text("${s['startTime']} - ${s['endTime']} | Lớp: ${s['classId']} | Phòng: ${classRooms[s['classId']] ?? 'N/A'}"),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
