import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Bảng màu chuẩn Organic Tech
  static const Color primaryColor = Color(0xFF004D40); // Deep Jungle Green
  static const Color secondaryColor = Color(0xFF00695C); // Teal Green (Dùng cho gradient)
  static const Color accentColor = Color(0xFFF59E0B); // Amber / Cam nhạt (CTA)
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light Grey
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937); // Dark Grey (dễ đọc hơn đen tuyền)
  static const Color textSecondary = Color(0xFF6B7280); // Grey

  // Font chữ chủ đạo
  static const String fontFamily = 'Nunito'; 

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFFFBBF24)], // Amber to Lighter Amber
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows - Đổ bóng siêu mờ và mềm mại
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(10), // Khoảng 4% opacity
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: primaryColor.withAlpha(30), // Bóng đổ mang sắc xanh nhẹ
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // Theme Data - Áp dụng cho toàn bộ App
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily, // Áp dụng font mặc định
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceColor,
      ),
      
      // Nút bấm (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bo 12px
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontFamily, 
            fontSize: 15, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Ô nhập liệu (TextField/Input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor, // Dùng nền xám nhạt để tạo chiều sâu
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontFamily: fontFamily, color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(fontFamily: fontFamily, color: textSecondary, fontSize: 14),
      ),
    );
  }
}