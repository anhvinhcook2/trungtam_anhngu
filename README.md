# Trung Tâm Anh Ngữ - English For Life

Đây là ứng dụng di động quản lý trung tâm anh ngữ được xây dựng bằng Flutter và Firebase. Ứng dụng hỗ trợ ba vai trò chính: Admin, Giáo viên và Học viên. Mỗi vai trò có một nhóm màn hình riêng, tập trung vào các công việc quản lý, giảng dạy và tra cứu học tập.

## 1. Tổng quan dự án

Ứng dụng này được thiết kế để hỗ trợ trung tâm anh ngữ trong các hoạt động:

- Quản lý người dùng theo vai trò: admin, teacher, student
- Quản lý giáo viên, học viên, lớp học và lịch học
- Theo dõi học phí
- Cho giáo viên nhập đánh giá, điểm số và nhận xét học tập
- Cho học viên/khách tra cứu thông tin học tập và lịch học
- Hỗ trợ trao đổi thông qua chat

## 2. Vai trò và trách nhiệm chính

### 2.1 Role: Admin
Admin là người điều hành hệ thống. Vai trò này có toàn quyền quản lý nội dung và dữ liệu chính của trung tâm.

Chức năng chính:
- Quản lý giáo viên: thêm, sửa, xóa hồ sơ giáo viên
- Quản lý học viên: thêm, sửa, xóa hồ sơ học viên, tạo mã học viên, theo dõi tình trạng học phí
- Quản lý lớp học: tạo lớp, gán giáo viên, gán học viên, xóa lớp
- Quản lý thời khóa biểu: tạo/sửa/xóa lịch học cho các lớp
- Quản lý học phí: bật/tắt trạng thái đóng học phí cho học viên
- Quản lý chat/hỗ trợ: xem các cuộc trao đổi của học viên/phụ huynh
- Xem tổng quan Dashboard: số lượng giáo viên, học viên, lớp, lịch, học phí, chat

### 2.2 Role: Teacher
Giáo viên là người trực tiếp giảng dạy và theo dõi học viên trong lớp mình phụ trách.

Chức năng chính:
- Xem danh sách các lớp mình phụ trách
- Gửi báo cáo nhanh sau tiết học cho lớp đang dạy
- Điểm danh học viên
- Xem danh sách học viên trong lớp
- Xem lịch sử đánh giá của từng học viên
- Thêm hoặc chỉnh sửa đánh giá định kỳ
- Nhập điểm số từ 0 đến 10
- Ghi nhận xét và thái độ học tập của học viên

### 2.3 Role: Student
Học viên sử dụng hệ thống để tra cứu thông tin học tập và xem các dữ liệu liên quan đến bản thân.

Chức năng chính:
- Tra cứu học viên bằng mã số học viên
- Xem thông tin cá nhân, mã học viên, trạng thái học phí
- Xem thời khóa biểu của lớp học
- Xem lịch sử đánh giá và nhận xét
- Gửi trao đổi/chat với admin
- Đăng xuất khỏi hệ thống

## 3. Bản đồ màn hình theo file và chức năng

| File màn hình | Vai trò | Chức năng chính |
|---|---|---|
| lib/main.dart | Tất cả | Điểm khởi động ứng dụng, khởi tạo Firebase và mở AuthWrapper |
| lib/navigation/auth_wrapper.dart | Tất cả | Sau khi đăng nhập, tự động điều hướng người dùng theo role: admin/teacher/student |
| lib/screens/auth_screen.dart | Tất cả | Màn hình đăng nhập bằng email và mật khẩu, chuyển hướng sau khi xác thực |
| lib/screens/student_dashboard.dart | Student | Tra cứu học viên bằng mã, xem thông tin học viên, trạng thái học phí, lịch học, lịch sử đánh giá và đăng xuất |
| lib/screens/teacher_dashboard.dart | Teacher | Hiển thị danh sách lớp do giáo viên phụ trách, gửi báo cáo nhanh, xem học viên trong lớp |
| lib/screens/evaluation_form.dart | Teacher | Form nhập/chỉnh sửa đánh giá định kỳ: điểm, thái độ, nhận xét |
| lib/screens/chat_screen.dart | Student, Teacher, Admin | Màn hình chat real-time giữa người dùng và admin |
| lib/screens/schedule_view.dart | Teacher, Student | Hiển thị thời khóa biểu theo lớp và theo tuần |
| lib/screens/splash_screen.dart | Tất cả | Màn hình chào tải ứng dụng |
| lib/screens/admin/admin_dashboard.dart | Admin | Dashboard tổng quan với các card quản lý giáo viên, học viên, lớp, lịch, học phí, chat |
| lib/screens/admin/admin_teacher_management.dart | Admin | Quản lý giáo viên: thêm, sửa tên, xóa hồ sơ |
| lib/screens/admin/admin_student_management.dart | Admin | Quản lý học viên: thêm, sửa tên, tạo mã học viên, xem trạng thái học phí, xóa hồ sơ |
| lib/screens/admin/admin_class_management.dart | Admin | Quản lý lớp học: tạo lớp, chọn giáo viên và phòng học, gán học viên, kiểm tra xung đột thời gian |
| lib/screens/admin/admin_schedule_management.dart | Admin | Quản lý thời khóa biểu: tạo/sửa lịch học, kiểm tra xung đột phòng học |
| lib/screens/admin/admin_tuition_management.dart | Admin | Quản lý học phí: xem và cập nhật trạng thái đóng tiền của học viên theo tháng |
| lib/screens/admin/admin_chat_list_screen.dart | Admin | Xem danh sách các cuộc trao đổi/chat |
| lib/screens/admin/student_progression_screen.dart | Admin | Xem lộ trình học của một học viên trong các lớp đã tham gia |

## 4. Chức năng chi tiết theo từng module

### 4.1 Module xác thực và phân quyền
- File chính: lib/services/auth_service.dart, lib/navigation/auth_wrapper.dart
- Vai trò: Tất cả
- Chức năng:
  - Đăng ký tài khoản mới qua Firebase Authentication
  - Đăng nhập bằng email/mật khẩu
  - Đăng xuất khỏi hệ thống
  - Lưu thông tin người dùng vào Firestore
  - Phân quyền tự động dựa trên trường role trong Firestore

### 4.2 Module quản trị Admin
- File chính: lib/screens/admin/*
- Vai trò: Admin
- Chức năng:
  - Quản lý giáo viên
  - Quản lý học viên
  - Quản lý lớp học
  - Quản lý lịch học
  - Quản lý học phí
  - Xem và truy cập chat hỗ trợ

### 4.3 Module giáo viên
- File chính: lib/screens/teacher_dashboard.dart, lib/screens/evaluation_form.dart
- Vai trò: Teacher
- Chức năng:
  - Xem lớp được phân công
  - Gửi feedback nhanh sau tiết học
  - Điểm danh học viên
  - Mở lịch sử đánh giá học viên
  - Nhập/chỉnh sửa đánh giá định kỳ

### 4.4 Module học viên
- File chính: lib/screens/student_dashboard.dart, lib/screens/schedule_view.dart, lib/screens/chat_screen.dart
- Vai trò: Student
- Chức năng:
  - Tra cứu học viên bằng mã số
  - Xem thông tin và trạng thái học phí
  - Xem lịch học
  - Xem đánh giá học tập
  - Trao đổi với admin

## 5. Cấu trúc thư mục chính

- lib/main.dart: điểm khởi động ứng dụng
- lib/navigation/: điều hướng và wrapper xác định vai trò đăng nhập
- lib/screens/: các màn hình chính
- lib/screens/admin/: các màn hình dành cho Admin
- lib/services/: xử lý auth và Firebase service
- lib/models/: model dữ liệu như UserModel
- lib/utils/: theme và tiện ích chung
- lib/widgets/: widget dùng chung
- lib/config/: file cấu hình liên quan Firestore rules
- functions/: Cloud Functions cho Firebase

## 6. Công nghệ sử dụng

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Material Design

## 7. Yêu cầu hệ thống

Trước khi chạy dự án, hãy đảm bảo bạn đã cài đặt:

- Flutter SDK
- Dart SDK
- Firebase CLI
- Android Studio hoặc VS Code với Flutter extension

## 8. Cài đặt

1. Clone repository:

```bash
git clone <repository-url>
cd trungtam_anhngu
```

2. Cài đặt dependencies:

```bash
flutter pub get
```

3. Cấu hình Firebase:

```bash
flutterfire configure
```

4. Chạy ứng dụng:

```bash
flutter run
```

## 9. Firebase setup

Các file cấu hình Firebase hiện có:

- lib/firebase_options.dart
- android/app/google-services.json
- firebase.json

## 10. Luồng dữ liệu chính

Dữ liệu chính được lưu trên Firestore với các collection:

- users: thông tin người dùng và role
- classes: dữ liệu lớp học
- schedules: thời khóa biểu
- reports: đánh giá, nhận xét, báo cáo nhanh
- attendance: điểm danh
- chats: chat giữa người dùng và admin
- tuition: thông tin học phí

## 11. Ghi chú quan trọng

- Một số thao tác quản trị như xóa tài khoản Authentication cần thực hiện thủ công trên Firebase Console.
- Nếu muốn dùng logo riêng ở màn hình đăng nhập, hãy thêm file assets/logo.png.
- Một số màn hình hiện đang là phiên bản MVP và có thể tiếp tục cải tiến về logic thời khóa biểu hoặc quản lý dữ liệu.

## 12. Kết luận

Dự án này là một hệ thống quản lý trung tâm anh ngữ cơ bản, tập trung vào ba vai trò chính: Admin, Giáo viên và Học viên. Mỗi vai trò có các màn hình và chức năng riêng, tạo thành một nền tảng quản lý toàn diện cho hoạt động giảng dạy và đào tạo.
