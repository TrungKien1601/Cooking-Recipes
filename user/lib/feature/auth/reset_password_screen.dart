import 'package:cooking_recipes_books/feature/home/homepage_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
// ⚠️ Đảm bảo bạn import đúng file Trang chủ của bạn

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode; // Nhận OTP từ màn hình trước

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  // --- HÀM XỬ LÝ ĐỔI MẬT KHẨU ---
  Future<void> _handleResetPassword() async {
    String newPass = _passController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    // Validation cơ bản
    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();
    // Gọi API (Server giờ sẽ trả về Token)
    bool success = await authService.resetPasswordWithOTP(
      widget.email,
      widget.otpCode,
      newPass,
    );  

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công! Đang vào trang chủ..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 🔥 CHUYỂN HƯỚNG VÀO HOMEPAGE (Xóa hết lịch sử back)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()), 
        (route) => false, 
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Lỗi hệ thống hoặc OTP hết hạn."),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text("Đặt Lại Mật Khẩu", style: GoogleFonts.outfit(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Thiết lập mật khẩu mới cho tài khoản:",
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              Text(
                widget.email,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),

              // Ô nhập Pass mới
              TextField(
                controller: _passController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ô nhập lại Pass
              TextField(
                controller: _confirmPassController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),

              // Nút Xác nhận
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FB239),
                    disabledBackgroundColor: const Color(0xFF4FB239).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Xác Nhận & Đăng Nhập",
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}