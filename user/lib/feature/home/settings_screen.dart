import '../recipe/add_recipe_screen.dart';
import '../auth/login_screen.dart';
import '../home/aboutus_screen.dart';
import '../home/privacyandpolicy_screen.dart';
import '../recipe/markdown_recipe_screen.dart';
import '../home/contactus_screen.dart';
// SỬA ĐỔI: Import file user_profile_screen.dart mới
import '../auth/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// SỬA ĐỔI: Chuyển về StatelessWidget (không cần quản lý state ở đây)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Định nghĩa màu sắc (trích xuất từ theme và các file khác)
  static const Color primaryBackground = Color(0xFFE3ECE1);
  static const Color appBarColor = Color(0xFF568C4C);
  static const Color primaryColor = Color(0xFF568C4C);
  static const Color secondaryBackground = Colors.white;
  static const Color primaryText = Color(0xFF15161E);
  static const Color secondaryText = Color(0xFF57636C);
  static const Color alternateBorder = Color(0xFFE0E3E7);
  static const Color errorColor = Color(0xFFFF5963);
  static const Color warningColor = Color(0xFFF57C00); // Màu vàng cảnh báo
  static const Color infoColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    // GestureDetector để unfocus khi nhấn ra ngoài
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: primaryBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  // Hàm xây dựng AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appBarColor,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      centerTitle: false,
      // Nút Back chuẩn
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white, // Đổi thành màu trắng cho dễ đọc
          size: 30.0,
        ),
        onPressed: () {
          // Dùng Navigator.pop chuẩn
          Navigator.of(context).pop();
        },
      ),
      // Tiêu đề chuẩn
      title: Text(
        'Settings',
        style: GoogleFonts.interTight(
          color: Colors.white, // Đổi thành màu trắng
          fontSize: 22.0, // Ước tính từ 'titleLarge'
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Hàm xây dựng Body
  Widget _buildBody(BuildContext context) {
    return SafeArea(
      top: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SỬA ĐỔI: Mục "Account"
              _buildAccountSection(context),
              const SizedBox(height: 24.0),
              // SỬA ĐỔI: Mục "Information"
              _buildAppInfoSection(context),
              const SizedBox(height: 24.0),
              _buildSecuritySection(context),
            ],
          ),
        ),
      ),
    );
  }

  // SỬA ĐỔI: Mục "Account" (Chỉ chứa nút User Profile)
  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Account',
            style: GoogleFonts.interTight(
              color: secondaryText,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              // Đây là nút duy nhất trong mục này
              _buildSettingsItem(
                context,
                icon: Icons.person_outline,
                title: "User Profile",
                subtitle: "Edit your profile and survey data",
                showArrow: true,
                onTap: () {
                  // SỬA ĐỔI: Điều hướng đến trang Profile mới
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SỬA ĐỔI: Mục "Information" (Không còn UID/Email)
  Widget _buildAppInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Information',
            style: GoogleFonts.interTight(
              color: secondaryText,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.add_circle_outline,
                title: "Add Recipe",
                showArrow: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddRecipeScreen()));
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                icon: Icons.bookmark_border,
                title: "Bookmark",
                showArrow: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MarkdownRecipeScreen()));
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: "Privacy & Policy",
                showArrow: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen()));
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                icon: Icons.info_outline,
                title: "About Us",
                showArrow: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutUsScreen()));
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                icon: Icons.contact_mail_outlined,
                title: "Contact Us",
                showArrow: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactUsScreen()));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Xây dựng phần "Account & Security"
  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Account & Security',
            style: GoogleFonts.interTight(
              color: secondaryText,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              _buildDivider(),
              _buildSettingsItem(
                context,
                icon: Icons.logout,
                title: "Log Out",
                subtitle: "Sign out of your account",
                iconColor: warningColor,
                titleColor: warningColor,
                onTap: () {
                  print("Tapped Log Out");
                  // Quay về trang Login và xóa hết các trang cũ
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false, // Xóa tất cả route
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Hàm trợ giúp tạo một hàng trong Cài đặt
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    final Color itemIconColor = iconColor ?? primaryColor;
    final Color itemTitleColor = titleColor ?? primaryText;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: itemIconColor, size: 24.0),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: itemTitleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          color: secondaryText,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
          if (showArrow)
            const Icon(Icons.chevron_right, color: secondaryText, size: 24.0),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  // Hàm trợ giúp tạo đường kẻ phân cách
  Widget _buildDivider() {
    return const Divider(
      height: 1.0,
      thickness: 1.0,
      indent: 16.0,
      endIndent: 16.0,
      color: alternateBorder,
    );
  }
}