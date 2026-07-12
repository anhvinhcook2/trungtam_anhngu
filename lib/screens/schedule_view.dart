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
  DateTime? _selectedWeekStart;
  List<DateTime> _availableWeeks = [];

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _initializeWeeks();
  }

  Future<void> _initializeWeeks() async {
    String? uid = widget.studentId ?? widget.teacherId;
    String role = widget.studentId != null ? 'student' : 'teacher';
    if (uid == null) return;

    Query classQuery = FirebaseFirestore.instance.collection('classes');
    if (role == 'teacher') {
      classQuery = classQuery.where('teacherId', isEqualTo: uid);
    } else {
      classQuery = classQuery.where('studentIds', arrayContains: uid);
    }

    var snapshot = await classQuery.get();
    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      setState(() => _selectedWeekStart = _getStartOfWeek(DateTime.now()));
      return;
    }

    DateTime minStart = DateTime.now();
    DateTime maxEnd = DateTime.now();
    bool first = true;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime start = (data['start_date'] as Timestamp).toDate();
      DateTime end = (data['end_date'] as Timestamp).toDate();

      if (first) {
        minStart = start;
        maxEnd = end;
        first = false;
      } else {
        if (start.isBefore(minStart)) minStart = start;
        if (end.isAfter(maxEnd)) maxEnd = end;
      }
    }

    List<DateTime> weeks = [];
    DateTime currentWeek = _getStartOfWeek(minStart);
    DateTime lastWeek = _getStartOfWeek(maxEnd);

    while (!currentWeek.isAfter(lastWeek)) {
      weeks.add(currentWeek);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    if (!mounted) return;
    setState(() {
      _availableWeeks = weeks;
      DateTime now = _getStartOfWeek(DateTime.now());
      // Nếu ngày hiện tại nằm trong range, set về tuần hiện tại, nếu không về tuần đầu tiên
      if (weeks.isNotEmpty && (now.isBefore(weeks.first) || now.isAfter(weeks.last))) {
        _selectedWeekStart = weeks.first;
      } else {
        _selectedWeekStart = now;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String? uid = widget.studentId ?? widget.teacherId;
    String role = widget.studentId != null ? 'student' : 'teacher';

    if (uid == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text(
            "Không tìm thấy người dùng để hiển thị lịch học.",
            style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700], fontSize: 16),
          ),
        ),
      );
    }

    Query classQuery = FirebaseFirestore.instance.collection('classes');
    if (role == 'teacher') {
      classQuery = classQuery.where('teacherId', isEqualTo: uid);
    } else {
      classQuery = classQuery.where('studentIds', arrayContains: uid);
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Thời Khóa Biểu", 
          style: TextStyle(
            fontFamily: _fontFamily, 
            fontWeight: FontWeight.w800,
            color: _primaryColor,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: _primaryColor),
        shape: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: classQuery.get(),
        builder: (context, classSnap) {
          if (!classSnap.hasData) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }
          
          List<String> myClassIds = classSnap.data!.docs.map((d) => d.id).toList();
          Map<String, Map<String, String>> classDetails = {};
          for (var doc in classSnap.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            classDetails[doc.id] = {
              'room': data['room'] ?? 'N/A',
              'name': data['name'] ?? 'N/A',
              'subject': data['subject'] ?? 'N/A',
            };
          }

          if (myClassIds.isEmpty || _selectedWeekStart == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Hiện tại chưa có lịch học nào.",
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeekPicker(),
              Expanded(child: _buildScheduleGrid(myClassIds, classDetails)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekPicker() {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableWeeks.length,
        itemBuilder: (context, index) {
          DateTime weekStart = _availableWeeks[index];
          DateTime weekEnd = weekStart.add(const Duration(days: 6));
          bool isSelected = weekStart.isAtSameMomentAs(_selectedWeekStart!);

          return GestureDetector(
            onTap: () => setState(() => _selectedWeekStart = weekStart),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Tuần ${index + 1}",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleGrid(List<String> classIds, Map<String, Map<String, String>> classDetails) {
    DateTime weekEnd = _selectedWeekStart!.add(const Duration(days: 7));
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schedules')
          .where('classId', whereIn: classIds)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedWeekStart!))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: TextStyle(fontFamily: _fontFamily)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Tuần này bạn đang trống lịch.',
                  style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }
        
        var schedules = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 7,
          itemBuilder: (context, i) {
            int day = i + 1;
            var daySchedules = schedules.where((s) => s['dayOfWeek'] == day).toList();
            
            if (daySchedules.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          day == 7 ? "CN" : "T${day + 1}", 
                          style: TextStyle(
                            fontFamily: _fontFamily, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 18,
                            color: _primaryColor,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: Column(
                      children: daySchedules.map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.access_time_filled_rounded, color: _accentColor, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${s['startTime']} - ${s['endTime']}",
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.grey.shade200, height: 1),
                            ),
                            
                            Row(
                              children: [
                                Icon(Icons.class_outlined, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Lớp: ${classDetails[s['classId']]?['name'] ?? 'N/A'} (${classDetails[s['classId']]?['subject'] ?? 'N/A'})",
                                    style: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.meeting_room_outlined, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(
                                  "Phòng: ${classDetails[s['classId']]?['room'] ?? 'N/A'}",
                                  style: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
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
