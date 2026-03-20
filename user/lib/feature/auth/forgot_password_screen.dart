import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  late FocusNode _emailFocusNode;
  bool _isLoading = false;
  
  // Khởi tạo Service (Singleton)
  final AuthService _authService = AuthService();

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

    // 🔥 SỬA QUAN TRỌNG: Gọi hàm sendOtp với type là 'forgot'
    // Thay vì gọi authService.forgotPassword(email) không tồn tại
    bool success = await _authService.sendOtp(
      email: email, 
      type: 'forgot'
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi mã OTP! Vui lòng kiểm tra email."),
          backgroundColor: Colors.green,
        ),
      );
      
      // Chuyển sang OTP Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            isForgotPassword: true, // Báo hiệu luồng quên mật khẩu
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor, size: 30.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Quay lại',
            style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 16.0, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 570.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 0.0, 0.0),
                  child: Text(
                    'Quên mật khẩu',
                    style: GoogleFonts.outfit(color: primaryTextColor, fontSize: 24.0, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                  child: Text(
                    'Chúng tôi sẽ gửi cho bạn một email có mã để đặt lại mật khẩu.',
                    style: GoogleFonts.plusJakartaSans(color: secondaryTextColor, fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ email...',
                      labelStyle: GoogleFonts.plusJakartaSans(color: secondaryTextColor, fontSize: 14.0, fontWeight: FontWeight.w500),
                      hintText: 'Nhập email của bạn...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: secondaryTextColor, fontSize: 14.0, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: whiteColor,
                      contentPadding: const EdgeInsets.all(24.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textFieldBorderColor, width: 2.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(color: primaryTextColor, fontSize: 14.0, fontWeight: FontWeight.w500),
                    cursorColor: focusedBorderColor,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: whiteColor,
                        fixedSize: const Size(270.0, 50.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      child: _isLoading 
                        ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: whiteColor, strokeWidth: 2.5))
                        : Text(
                            'Gửi mã',
                            style: GoogleFonts.plusJakartaSans(fontSize: 20.0, fontWeight: FontWeight.w500),
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