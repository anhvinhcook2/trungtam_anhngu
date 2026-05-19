import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  String _selectedRole = 'student';
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    String? error;

    if (_isLogin) {
      error = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      error = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
    }

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(_isLogin ? "Đăng Nhập" : "Đăng Ký",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              if (!_isLogin)
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Họ và tên")),
              const SizedBox(height: 15),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu")),
              if (!_isLogin) ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text("Giáo viên")),
                    DropdownMenuItem(value: 'student', child: Text("Học viên")),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: const InputDecoration(labelText: "Vai trò"),
                ),
              ],
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: _submit, child: Text(_isLogin ? "Đăng Nhập" : "Tạo Tài Khoản")),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? "Chưa có tài khoản? Đăng ký" : "Đã có tài khoản? Đăng nhập"),
              )
            ],
          ),
        ),
      ),
    );
  }
}