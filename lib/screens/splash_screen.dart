import 'package:flutter/material.dart';
import '../utils/app_theme.dart'; // Bạn có thể giữ để dùng các config khác nếu cần
import '../navigation/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // --- BẢNG MÀU CHUẨN CONCEPT ORGANIC TECH ---
  final Color _primaryColor = const Color(0xFF004D40); // Deep Jungle Green
  final Color _bgColor = const Color(0xFFF8F9FA); // Light Grey
  final String _fontFamily = 'Nunito';

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Chuyển hướng sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor, // Nền xám nhạt đồng bộ concept
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 140, // Kích thước tinh chỉnh lại gọn gàng hơn
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), // Bóng đổ cực mờ (soft shadow)
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                // Sử dụng errorBuilder để tránh crash nếu user chưa cho ảnh vào thư mục assets
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.school_rounded, size: 70, color: _primaryColor);
                  },
                ),
              ),
            ),
            const SizedBox(height: 36),
            
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                );
              },
              child: Column(
                children: [
                  Text(
                    "ENGLISH CENTER",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _primaryColor, // Đổi sang Deep Jungle Green
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enterprise Management System",
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700, // Đậm nhẹ để dễ đọc
                      color: Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            
            // Loading Indicator dùng màu chủ đạo
            CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
