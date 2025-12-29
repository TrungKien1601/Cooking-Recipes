import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'otp_screen.dart'; 
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final Color primaryColor = const Color(0xFF568C4C);
  final Color primaryBackgroundColor = const Color(0xFFF1F4F8);
  final Color secondaryTextColor = const Color(0xFF57636C);
  final Color textFieldBorderColor = const Color(0xFFE0E3E7);
  final Color whiteColor = const Color(0xFFFFFFFF);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- HÀM ĐĂNG KÝ (ĐÃ SỬA LỖI) ---
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = AuthService();
  
    // Vì AuthService.sendOtp bây giờ dùng named parameter {email, phone, type}
    bool isSent = await authService.sendOtp(
      email: _emailController.text.trim(), 
      type: 'register'
    );

    setState(() => _isLoading = false);

    if (isSent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mã OTP đã được gửi! Vui lòng kiểm tra email."), 
          backgroundColor: Colors.green
        )
      );

      // Chuyển sang trang OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
            // Vẫn truyền phone sang để lưu vào DB khi xác thực xong
            phone: _phoneController.text.trim(), 
            isForgotPassword: false,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email này đã tồn tại hoặc lỗi hệ thống."), 
          backgroundColor: Colors.red
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create Account', textAlign: TextAlign.center, style: GoogleFonts.interTight(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text('Join us to explore delicious recipes!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16.0, color: secondaryTextColor)),
                        const SizedBox(height: 30),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          validator: (val) => val!.isEmpty ? "Vui lòng nhập họ tên" : null,
                          decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => (!val!.contains('@gmail.com')) ? "Email không hợp lệ" : null,
                          decoration: _buildInputDecoration('Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (val) => (val!.isEmpty || val.length < 9 ) ? "Số điện thoại không hợp lệ" : null,
                          decoration: _buildInputDecoration('Phone Number', Icons.phone_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          validator: (val) => val!.length < 6 ? "Mật khẩu phải hơn 6 ký tự" : null,
                          decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: secondaryTextColor),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPassController,
                          obscureText: !_confirmPasswordVisible,
                          validator: (val) => val != _passwordController.text ? "Mật khẩu không khớp" : null,
                          decoration: _buildInputDecoration('Confirm Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_confirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: secondaryTextColor),
                              onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: _handleSignUp,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: whiteColor, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), elevation: 3.0),
                          child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.w600)),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?  ', style: GoogleFonts.inter(color: secondaryTextColor)),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                              child: Text('Login', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: GoogleFonts.inter(color: secondaryTextColor), filled: true, fillColor: whiteColor, prefixIcon: Icon(icon, color: secondaryTextColor),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textFieldBorderColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
      focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
    );
  }
}