import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';

class EvaluationFormScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  final String? reportId;
  final Map<String, dynamic>? initialData;

  const EvaluationFormScreen({
    super.key,
    required this.studentId,
    required this.classId,
    this.reportId,
    this.initialData,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  String _attitude = 'Tốt';
  final List<String> _attitudeOptions = ['Rất tốt', 'Tốt', 'Trung bình', 'Cần cải thiện'];
  bool _isSaving = false;

  // --- BẢNG MÀU & FONT CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _scoreController.text = (widget.initialData!['scores'] ?? widget.initialData!['score'] ?? '').toString();
      _commentController.text = widget.initialData!['comments'] ?? widget.initialData!['comment'] ?? '';
      if (_attitudeOptions.contains(widget.initialData!['attitude'])) {
        _attitude = widget.initialData!['attitude'];
      }
    }
  }

  Future<void> _saveEvaluation() async {
    double? score = double.tryParse(_scoreController.text);
    if (score == null || score < 0 || score > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập điểm hợp lệ (0-10)"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập nhận xét chi tiết"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String teacherId = FirebaseAuth.instance.currentUser!.uid;
      final data = {
        'type': 'periodic',
        'student_id': widget.studentId,
        'teacher_id': teacherId,
        'class_id': widget.classId,
        'scores': score,
        'attitude': _attitude,
        'comments': _commentController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.reportId == null) {
        data['timestamp'] = FieldValue.serverTimestamp();
        await _db.collection('reports').add(data);
      } else {
        await _db.collection('reports').doc(widget.reportId).update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu đánh giá!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.reportId != null;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          isEdit ? "Sửa Đánh Giá" : "Đánh Giá Định Kỳ",
          style: TextStyle(
            fontFamily: _fontFamily,
            color: _primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Điểm Số ---
              Text(
                "Điểm số (0 - 10)",
                style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "VD: 8.5",
                  hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[400]),
                  filled: true,
                  fillColor: _bgColor, // Đồng bộ màu nền xám nhạt cho input
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Thái Độ ---
              Text(
                "Thái độ học tập",
                style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _attitude,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: _attitudeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) setState(() => _attitude = newValue);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Nhận Xét ---
              Text(
                "Nhận xét chi tiết",
                style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 15, color: Colors.black87, height: 1.4),
                decoration: InputDecoration(
                  hintText: "Nhập điểm mạnh, điểm yếu của học viên...",
                  hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[400]),
                  filled: true,
                  fillColor: _bgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Nút CTA ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor, // Dùng màu điểm nhấn (Vàng/Cam)
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveEvaluation,
                  child: _isSaving 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      ) 
                    : Text(
                        isEdit ? "CẬP NHẬT ĐÁNH GIÁ" : "LƯU ĐÁNH GIÁ", 
                        style: TextStyle(
                          fontFamily: _fontFamily, 
                          fontSize: 15, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 0.5,
                        ),
                      ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}