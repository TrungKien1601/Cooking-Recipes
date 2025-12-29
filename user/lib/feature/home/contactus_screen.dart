import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Định nghĩa màu sắc (trích xuất từ theme) ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C); // Màu xanh lá chính
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorError = Color(0xFFFF5963);
const Color kColorInfo = Colors.white; // Màu chữ của nút

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn nút Gửi
  void _submitForm() {
    // Kiểm tra xem form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      // Nếu hợp lệ, xử lý logic
      print('Form submitted!');
      print('Name: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('Message: ${_messageController.text}');
      
      // TODO: Thêm logic gửi email hoặc lưu vào database

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          backgroundColor: kColorPrimary,
        ),
      );

      // Xóa nội dung các ô
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: _buildAppBar(context),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32.0),
                  _buildContactInfoCard(),
                  const SizedBox(height: 32.0),
                  _buildContactForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- CÁC HÀM XÂY DỰNG UI ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kColorBackground,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: kColorPrimaryText),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Contact Us',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 22.0, // headlineMedium
        ),
      ),
    );
  }

  // Tiêu đề và mô tả
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get In Touch',
          style: GoogleFonts.interTight(
            color: kColorPrimaryText,
            fontSize: 28.0, // headlineMedium
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          "We'd love to hear from you. Fill out the form below or use our contact details.",
          style: GoogleFonts.inter(
            color: kColorSecondaryText,
            fontSize: 16.0, // bodyLarge
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Thẻ thông tin (Email, Phone, Address)
  Widget _buildContactInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kColorBorder, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'contact@recipeapp.com',
            ),
            const Divider(height: 32.0, color: kColorBorder),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+1 (555) 123-4567',
            ),
            const Divider(height: 32.0, color: kColorBorder),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Address',
              subtitle: '123 Recipe Lane, Food City, USA',
            ),
          ],
        ),
      ),
    );
  }

  // Hàm trợ giúp cho một hàng thông tin (Icon, Title, Subtitle)
  Widget _buildInfoRow(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kColorPrimary, size: 24.0),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.interTight(
                  color: kColorPrimaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: kColorSecondaryText,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Form nhập liệu
  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send us a Message',
            style: GoogleFonts.interTight(
              color: kColorPrimaryText,
              fontSize: 28.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24.0),
          _buildTextField(
            controller: _nameController,
            label: 'Your Name',
            hint: 'Enter your name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _buildTextField(
            controller: _emailController,
            label: 'Your Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            hint: 'Write your message here...',
            minLines: 5,
            maxLines: 8,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your message';
              }
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50.0),
              backgroundColor: kColorPrimary,
              foregroundColor: kColorInfo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              'Send Message',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm trợ giúp tạo các trường nhập liệu
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14.0),
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: kColorSecondaryText, fontSize: 16.0),
        filled: true,
        fillColor: kColorCard,
        contentPadding: const EdgeInsets.all(16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: kColorBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: kColorBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: kColorPrimary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: kColorError, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: kColorError, width: 2.0),
        ),
      ),
      style: GoogleFonts.inter(color: kColorPrimaryText, fontSize: 16.0),
      cursorColor: kColorPrimary,
      validator: validator,
    );
  }
}