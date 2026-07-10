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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? "Sửa Đánh Giá" : "Đánh Giá Định Kỳ", style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Điểm số (0 - 10)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "VD: 8.5",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Thái độ học tập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _attitude,
                  isExpanded: true,
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
            
            const Text("Nhận xét chi tiết", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: "Điểm mạnh, điểm yếu...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 40),

            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveEvaluation,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(isEdit ? "CẬP NHẬT" : "LƯU ĐÁNH GIÁ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
