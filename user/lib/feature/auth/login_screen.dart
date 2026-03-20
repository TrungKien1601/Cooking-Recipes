import '../home/homepage_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import để lưu cache
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dart:convert';
import '../survey/collect_information_screen.dart'; 
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color primaryColor = const Color(0xFF568C4C);
  final Color primaryBackgroundColor = const Color(0xFFF1F4F8);
  final Color secondaryTextColor = const Color(0xFF57636C);
  final Color textFieldBorderColor = const Color(0xFFE0E3E7);
  final Color whiteColor = const Color(0xFFFFFFFF);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  
  bool _isLoading = false; 
  // final _formKey = GlobalKey<FormState>(); 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // HÀM 1: XỬ LÝ LOGIN GOOGLE (ĐÃ SỬA)
  // ============================================================
  // Future<void> _handleGoogleLogin() async {
  //   setState(() => _isLoading = true);
    
  //   final authService = AuthService();
  //   final result = await authService.loginWithGoogle();
  
  //   setState(() => _isLoading = false);

  //   if (result['success'] == true) {
  //     String token = result['token'];
  //     String userId = result['userId'];
  //     bool isSurveyDone = result['isSurveyDone'] == true; 
  //     final userData = result['data'];

  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('token', token);
  //     await prefs.setString('userId', userId);

  //     if (userData != null) {
  //       await prefs.setString('user_data', jsonEncode(userData));
  //     }

  //     if (!mounted) return;
      
  //     if (isSurveyDone) {
  //       Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (context) => const HomePage()),
  //         (route) => false,
  //       );
  //     } else {
  //       Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (context) => OnboardingFlowScreen(userId: userId)),
  //         (route) => false,
  //       );
  //     }
  //   } else {
  //     _showError(result['message'] ?? "Đăng nhập Google thất bại.");
  //   }
  // }

  // ============================================================
  // HÀM 2: XỬ LÝ LOGIN EMAIL/PASS 
  // ============================================================
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }
  Future<void> _handleLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  // 1. Validate kỹ hơn
    if (email.isEmpty || password.isEmpty) {
      _showError("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Định dạng email không hợp lệ");
      return;
    }

  setState(() => _isLoading = true);

  final authService = AuthService();

  // 2. Gọi API đăng nhập
  final result = await authService.signInWithEmail(
    _emailController.text.trim(),
    _passwordController.text.trim(),
  );

  setState(() => _isLoading = false);

  // 3. Kiểm tra kết quả
  if (result['success'] == true) {
    // --- ĐĂNG NHẬP THÀNH CÔNG ---
    
    // Lấy dữ liệu từ API trả về
    String userId = result['userId'];
    String token = result['token'];
    final userData = result['data'];
    
    // Kiểm tra cờ isSurveyDone từ Backend trả về (quan trọng)
    bool isSurveyDone = result['isSurveyDone'] ?? false;

    // Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setBool('isSurveyDone', isSurveyDone);
    
    if (userData != null) {
      await prefs.setString('user_data', jsonEncode(userData));
    }

    print("✅ Login Success: Token: $token - SurveyDone: $isSurveyDone");

    if (!mounted) return;
    // Dùng luôn biến isSurveyDone vừa lấy được, không cần if (loginSuccess) nữa
    if (isSurveyDone) {
      // Đã làm khảo sát -> Vào Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      // Chưa làm khảo sát -> Vào Survey
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => OnboardingFlowScreen(userId: userId)
        ),
        (route) => false,
      );
    }

  } else {
    // --- ĐĂNG NHẬP THẤT BẠI ---
    _showError(result['message'] ?? "Đăng nhập thất bại");
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER ---
                  Text('Đăng nhập', style: GoogleFonts.interTight(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Text('Chào mừng, vui lòng nhập thông tin của bạn.', style: GoogleFonts.inter(fontSize: 16.0, color: secondaryTextColor)),
                  const SizedBox(height: 40),
  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email', hintText: 'Nhập email của bạn...', labelStyle: GoogleFonts.inter(color: secondaryTextColor),
                      filled: true, fillColor: whiteColor, prefixIcon: Icon(Icons.email_outlined, color: secondaryTextColor),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textFieldBorderColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
                    ),
                    style: GoogleFonts.inter(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu', hintText: 'Nhập mật khẩu của bạn...', labelStyle: GoogleFonts.inter(color: secondaryTextColor),
                      filled: true, fillColor: whiteColor, prefixIcon: Icon(Icons.lock_outline, color: secondaryTextColor),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: secondaryTextColor),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textFieldBorderColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2.0), borderRadius: BorderRadius.circular(12.0)),
                    ),
                    style: GoogleFonts.inter(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                      child: Text('Quên mật khẩu?', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14.0)),
                    ),
                  ),
                  const SizedBox(height: 24),
  
                  // --- NÚT LOGIN CHÍNH ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      elevation: 3.0,
                    ),
                    child: Text(
                      'Đăng nhập',
                      style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.w600),
                    ),
                  ),
  
                  const SizedBox(height: 30),
  
                  // --- DIVIDER ---
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Expanded(
                  //       child: Divider(color: secondaryTextColor.withOpacity(0.5), thickness: 1)),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //       child: Text('Or continue with', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 14.0)),
                  //     ),
                  //     Expanded(child: Divider(color: secondaryTextColor.withOpacity(0.5), thickness: 1)),
                  //   ],
                  // ),
  
                  // const SizedBox(height: 30),
                  
                  // --- NÚT GOOGLE ---
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       decoration: BoxDecoration(
                  //         color: whiteColor,
                  //         shape: BoxShape.circle,
                  //         border: Border.all(color: textFieldBorderColor, width: 2.0),
                  //         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  //       ),
                  //       child: IconButton(
                  //         onPressed: _isLoading ? null : _handleGoogleLogin, 
                  //         icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 40), 
                  //         padding: const EdgeInsets.all(8.0),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // const SizedBox(height: 30), 
                  
                   // Link Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('bạn chưa có tài khoản ?  ', style: GoogleFonts.inter(color: secondaryTextColor)),
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                        child: Text('Đăng ký', style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600)),
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
}