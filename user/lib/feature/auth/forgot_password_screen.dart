import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart'; // Đảm bảo import đúng đường dẫn file OTP

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Quản lý state trực tiếp
  late TextEditingController _emailController;
  late FocusNode _emailFocusNode;
  bool _isLoading = false;

  // Định nghĩa màu sắc
  final Color primaryBackgroundColor = const Color(0xFFF1F4F8);
  final Color primaryTextColor = const Color(0xFF15161E);
  final Color secondaryTextColor = const Color(0xFF606A85);
  final Color textFieldBorderColor = const Color(0xFFE5E7EB);
  final Color focusedBorderColor = const Color(0xFF6F61EF);
  final Color errorBorderColor = const Color(0xFFFF5963);
  final Color buttonColor = const Color(0xFF4FB239);
  final Color whiteColor = Colors.white;
  
  // --- HÀM XỬ LÝ GỬI LINK ---
  Future<void> _handleSendLink() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Gọi API từ AuthService
    final authService = AuthService();
    // Lưu ý: Hàm forgotPassword thường chỉ cần email để gửi OTP
    bool success = await authService.forgotPassword(email: email);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi mã OTP! Vui lòng kiểm tra email."),
          backgroundColor: Colors.green,
        ),
      );
      
      // 🔥 CHUYỂN HƯỚNG SANG MÀN HÌNH OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            isForgotPassword: true, // 🚩 Báo hiệu đây là luồng quên mật khẩu
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gửi thất bại. Email không tồn tại hoặc lỗi server."),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBackgroundColor,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: primaryTextColor,
            size: 30.0,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Back',
            style: GoogleFonts.outfit(
              color: primaryTextColor,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 570.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 0.0, 0.0),
                  child: Text(
                    'Forgot Password',
                    style: GoogleFonts.outfit(
                      color: primaryTextColor,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Mô tả
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                  child: Text(
                    'We will send you an email with a code to reset your password.',
                    style: GoogleFonts.plusJakartaSans(
                      color: secondaryTextColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Trường nhập Email
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    obscureText: false,
                    decoration: InputDecoration(
                      labelText: 'Your email address...',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color: secondaryTextColor,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Enter your email...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: secondaryTextColor,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: whiteColor,
                      contentPadding:
                          const EdgeInsets.fromLTRB(24.0, 24.0, 20.0, 24.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textFieldBorderColor,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: focusedBorderColor,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: errorBorderColor,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: errorBorderColor,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryTextColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: focusedBorderColor,
                  ),
                ),
                // Nút Gửi Link (Đã cập nhật logic)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton(
                      // Nếu đang loading thì disable nút
                      onPressed: _isLoading ? null : _handleSendLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: whiteColor,
                        disabledBackgroundColor: buttonColor.withOpacity(0.6),
                        elevation: 3.0,
                        fixedSize: const Size(270.0, 50.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      // Hiển thị vòng quay loading khi đang xử lý
                      child: _isLoading 
                        ? SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(
                              color: whiteColor, 
                              strokeWidth: 2.5
                            )
                          )
                        : Text(
                            'Send Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}