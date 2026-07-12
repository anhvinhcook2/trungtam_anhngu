import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import 'student_progression_screen.dart';

class AdminStudentManagement extends StatefulWidget {
  const AdminStudentManagement({super.key});

  @override
  State<AdminStudentManagement> createState() => _AdminStudentManagementState();
}

class _AdminStudentManagementState extends State<AdminStudentManagement> {
  final _db = FirebaseFirestore.instance;
  final _fs = FirebaseService();

  bool _isProcessing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Chỉ lọc 'Tất cả' hoặc 'Còn nợ'
  String _filterStatus = 'Tất cả'; 

  // ==================== LOGIC XỬ LÝ ====================

  void _showAddDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Thêm Học Viên Mới", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(labelText: "Họ và tên", prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailC,
                      decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passC,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Mật khẩu (từ 6 ký tự)", prefixIcon: Icon(Icons.lock)),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!_isProcessing) ...[
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Hủy", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.length < 6) return;
                    setDialogState(() => _isProcessing = true);
                    FirebaseApp? tempApp;
                    try {
                      tempApp = await _fs.createSecondaryInstance();
                      UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
                          email: emailC.text.trim(), password: passC.text.trim());

                      String sCode = _fs.generateStudentCode();
                      await _db.collection('users').doc(res.user!.uid).set({
                        'uid': res.user!.uid,
                        'email': emailC.text,
                        'name': nameC.text,
                        'role': 'student',
                        'student_code': sCode,
                        'tuition_status': 'Chưa đóng',
                        'updatedAt': FieldValue.serverTimestamp()
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } finally {
                      await tempApp?.delete();
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                  child: const Text("Lưu"),
                ),
              ]
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(String uid, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sửa thông tin", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Họ và tên mới", prefixIcon: Icon(Icons.edit)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _db.collection('users').doc(uid).update({'name': nameCtrl.text});
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã cập nhật tên!"), backgroundColor: Colors.green)
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(String uid, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("Xóa học viên $email?\nLưu ý: Bạn cần vào Firebase Console để xóa tài khoản Auth thủ công!"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.collection('users').doc(uid).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa hồ sơ."), backgroundColor: Colors.teal)
      );
    }
  }

  // ==================== GIAO DIỆN ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Quản lý Học viên", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsSummary(),
          _buildFilterChips(),
          Expanded(child: _buildStudentsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm học viên", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: const InputDecoration(
          hintText: "Tìm kiếm tên, email học viên...",
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Tất cả', 'Còn nợ'].map((status) {
          bool isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() => _filterStatus = status);
              },
              selectedColor: isSelected ? const Color(0xFF4F46E5).withAlpha(50) : null,
              checkmarkColor: const Color(0xFF4F46E5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs;
        final total = docs.length;

        return FutureBuilder<int>(
          future: _countDebtors(docs),
          builder: (context, snapshot) {
            final debt = snapshot.data ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildSummaryCard("Tổng số", "$total", Icons.people, Colors.indigo, null),
                  const SizedBox(width: 12),
                  _buildSummaryCard("Chưa đóng học phí", "$debt", Icons.payments, debt > 0 ? Colors.orange : Colors.green, 'Còn nợ'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int> _countDebtors(List<DocumentSnapshot> students) async {
    String month = DateTime.now().toString().substring(0, 7);
    int count = 0;
    for (var s in students) {
      var tuition = await _db.collection('tuition')
          .where('studentId', isEqualTo: s.id)
          .where('month', isEqualTo: month)
          .where('status', isEqualTo: 'pending')
          .get();
      if (tuition.docs.isNotEmpty) count++;
    }
    return count;
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String? filter) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (filter != null) setState(() => _filterStatus = filter);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>;
            // Kiểm tra nợ
            String month = DateTime.now().toString().substring(0, 7);
            var tuition = await _db.collection('tuition')
                .where('studentId', isEqualTo: doc.id)
                .where('month', isEqualTo: month)
                .where('status', isEqualTo: 'pending')
                .get();
            bool isOwing = tuition.docs.isNotEmpty;
            return {
              'doc': doc,
              'isOwing': isOwing,
              'data': data
            };
          })),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var studentDataList = snapshot.data!;
            
            // Search & Filter Logic
            studentDataList = studentDataList.where((item) {
              final data = item['data'];
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final isOwing = item['isOwing'];
              
              final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery);
              final matchesFilter = _filterStatus == 'Tất cả' || (isOwing && _filterStatus == 'Còn nợ');
              
              return matchesSearch && matchesFilter;
            }).toList();

            if (studentDataList.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Text("Không tìm thấy học viên nào.", style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: studentDataList.length,
              itemBuilder: (context, index) {
                final item = studentDataList[index];
                final doc = item['doc'] as DocumentSnapshot;
                final data = item['data'];
                final name = data['name'] ?? 'Không tên';
                final email = data['email'] ?? 'Chưa có email';
                final code = data['student_code'] ?? data['studentCode'] ?? "Chưa cấp mã";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.indigo.shade100)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 20)
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                            _buildStudentDebtSummary(doc.id),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Mã HV: $code", style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.timeline_rounded, size: 22, color: Colors.teal),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProgressionScreen(studentId: doc.id, studentName: name))),
                                  tooltip: 'Lộ trình',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 22, color: Colors.blue),
                                  onPressed: () => _showEditDialog(doc.id, name),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 22, color: Colors.redAccent),
                                  onPressed: () => _deleteStudent(doc.id, email),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStudentDebtSummary(String studentId) {
    String month = DateTime.now().toString().substring(0, 7);
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('tuition')
          .where('studentId', isEqualTo: studentId)
          .where('month', isEqualTo: month)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text("Nợ ${snapshot.data!.docs.length} môn", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
