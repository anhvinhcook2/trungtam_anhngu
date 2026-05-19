import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'navigation/auth_wrapper.dart'; // Import bộ điều hướng

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EnglishCenterApp());
}

class EnglishCenterApp extends StatelessWidget {
  const EnglishCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Trung Tâm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        // Định dạng chung cho các ô nhập liệu trong toàn app
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      // Gọi AuthWrapper để xử lý lộ trình người dùng
      home: const AuthWrapper(),
    );
  }
}