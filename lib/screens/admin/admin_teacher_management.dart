import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

class AdminTeacherManagement extends StatefulWidget {
  const AdminTeacherManagement({super.key});

  @override
  State<AdminTeacherManagement> createState() => _AdminTeacherManagementState();
}

class _AdminTeacherManagementState extends State<AdminTeacherManagement> {
  final _fs = FirebaseService();
  final _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSubject;

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final Color _accentColor = const Color(0xFFF59E0B); // Vàng nghệ / Cam nhạt
  final String _fontFamily = 'Nunito';

  // Helper cho giao diện Input
  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Thêm Giáo Viên Mới",
            style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 18),
          ),
          content: _isLoading
              ? SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: _primaryColor)),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                decoration: _customInputDecoration("Họ và tên"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailC,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                decoration: _customInputDecoration("Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passC,
                obscureText: true,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
                decoration: _customInputDecoration("Mật khẩu"),
              ),
            ],
          ),
          actions: _isLoading ? [] : [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.length < 6) return;
                setDialogState(() => _isLoading = true);

                FirebaseApp? tempApp;
                try {
                  tempApp = await _fs.createSecondaryInstance();
                  UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
                      email: emailC.text.trim(), password: passC.text.trim());
                  await _db.collection('users').doc(res.user!.uid).set({
                    'uid': res.user!.uid, 'name': nameC.text, 'email': emailC.text,
                    'role': 'teacher', 'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm giáo viên thành công!"), backgroundColor: Colors.green));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent));
                } finally {
                  await tempApp?.delete();
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Text("Xác nhận", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String uid, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Sửa tên giáo viên", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 18)),
        content: TextField(
          controller: nameCtrl,
          style: TextStyle(fontFamily: _fontFamily, fontSize: 15),
          decoration: _customInputDecoration("Họ và tên mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _db.collection('users').doc(uid).update({'name': nameCtrl.text});
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật tên!"), backgroundColor: Colors.green));
              }
            },
            child: Text("Lưu", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeacher(String uid, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Xác nhận xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 18)),
        content: Text(
          "Bạn đang xóa dữ liệu của giáo viên: $email\n\nLưu ý: Bạn cần vào mục Authentication trên Firebase Console để xóa thủ công tài khoản này!",
          style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Xóa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.collection('users').doc(uid).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa hồ sơ giáo viên!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Quản lý Giáo viên", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsSummary(),
          Expanded(child: _buildTeacherList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm giáo viên", style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
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
          hintText: "Tìm kiếm tên, email giáo viên...",
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('classes').snapshots(),
      builder: (context, classSnapshot) {
        Set<String> subjects = {};
        if (classSnapshot.hasData) {
          for (var doc in classSnapshot.data!.docs) {
            subjects.add(doc['subject']);
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
          builder: (context, userSnapshot) {
            final total = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt, color: _primaryColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Tổng GV", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text("$total", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Chọn môn", style: TextStyle(fontSize: 13)),
                          value: _selectedSubject,
                          onChanged: (val) => setState(() => _selectedSubject = val),
                          items: [
                            const DropdownMenuItem(value: null, child: Text("Tất cả môn")),
                            ...subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                          ],
                        ),
                      ),
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

  Widget _buildTeacherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator(color: _primaryColor));

        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('classes').snapshots(),
          builder: (context, classSnapshot) {
            if (!classSnapshot.hasData) return const SizedBox.shrink();

            var docs = userSnapshot.data!.docs;

            // Logic lọc theo môn học: Tìm các teacherId dạy môn đó
            if (_selectedSubject != null) {
              Set<String> validTeacherIds = {};
              for (var doc in classSnapshot.data!.docs) {
                if (doc['subject'] == _selectedSubject) {
                  validTeacherIds.add(doc['teacherId']);
                }
              }
              docs = docs.where((d) => validTeacherIds.contains(d.id)).toList();
            }

            // Lọc theo tìm kiếm
            if (_searchQuery.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();
            }

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text("Không tìm thấy giáo viên.", style: TextStyle(fontFamily: _fontFamily, color: Colors.grey[500], fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Không tên';
                final email = data['email'] ?? 'Chưa có email';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _primaryColor.withValues(alpha: 0.1))
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
                                  color: _accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 20)
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
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showEditDialog(doc.id, name),
                              icon: Icon(Icons.edit, size: 18, color: Colors.blue.shade600),
                              label: Text("Sửa", style: TextStyle(color: Colors.blue.shade600)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteTeacher(doc.id, email),
                              icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
                              label: Text("Xóa", style: TextStyle(color: Colors.red.shade400)),
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
}
