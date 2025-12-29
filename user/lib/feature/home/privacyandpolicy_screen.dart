import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// --- Định nghĩa màu sắc (trích xuất từ theme) ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C); // Màu xanh lá chính
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorInfo = Colors.white;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        // SỬA ĐỔI: Thêm AppBar thật, xóa nút 'Back' khỏi body
        appBar: _buildAppBar(context),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề và ngày cập nhật (từ code gốc)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.interTight(
                        color: kColorPrimaryText,
                        fontSize: 28.0, // displaySmall
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Text(
                      'Last updated: December 15, 2024',
                      style: GoogleFonts.inter(
                        color: kColorSecondaryText,
                        fontSize: 14.0, // labelMedium
                      ),
                    ),
                  ),

                  // Thẻ nội dung
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kColorCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Đổi từ 16
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'Information We Collect',
                            body:
                                'We collect information you provide directly to us, such as when you create an account, update your profile, or otherwise communicate with us.',
                          ),
                          _buildSection(
                            title: 'How We Use Your Information',
                            body:
                                'We use the information we collect to provide, maintain, and improve our services, including to process transactions and send you related information.',
                          ),
                          _buildSection(
                            title: 'Information Sharing',
                            body:
                                'We do not sell, trade, or otherwise transfer to outside parties your Personally Identifiable Information unless we provide users with advance notice.',
                          ),
                          _buildSection(
                            title: 'Data Security',
                            body:
                                'We implement appropriate technical and organizational measures to protect the security of your personal information against accidental or unlawful destruction, loss, or alteration.',
                          ),
                          _buildSection(
                            title: 'Your Rights',
                            body:
                                'You have the right to access, update, or delete the information we have on you. You can also object to processing, request restriction of processing, and request data portability.',
                          ),
                          _buildSection(
                            title: 'Cookies and Tracking',
                            body:
                                'We use cookies and similar tracking technologies to track activity on our service and hold certain information. You can instruct your browser to refuse all cookies.',
                          ),
                          _buildSection(
                            title: 'Children\'s Privacy',
                            body:
                                'Our services are not intended for anyone under the age of 13 ("Children"). We do not knowingly collect personal identifiable information from children under 13.',
                          ),
                          _buildSection(
                            title: 'Changes to This Policy',
                            body:
                                'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date.',
                          ),
                          // Phần Contact Us (có style khác)
                          _buildContactSection(context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0), // Đệm dưới cùng
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kColorBackground,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      // Nút Back
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: kColorPrimaryText),
        onPressed: () => Navigator.of(context).pop(),
      ),
      // Bỏ title trong AppBar vì nó đã có trong body
    );
  }

  // Hàm trợ giúp để tạo một Mục (Section)
  Widget _buildSection({
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.interTight(
              color: kColorPrimaryText,
              fontWeight: FontWeight.w600,
              fontSize: 24.0, // headlineSmall
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            body, // Dùng văn bản (text) đầy đủ hơn
            style: GoogleFonts.inter(
              color: kColorSecondaryText,
              fontSize: 14.0, // bodyMedium
              height: 1.5, // Dãn dòng
            ),
          ),
        ],
      ),
    );
  }

  // Hàm riêng cho phần "Contact Us"
  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: kColorBorder, height: 1.0, thickness: 1.0),
        const SizedBox(height: 24.0),
        Text(
          'Contact Us',
          style: GoogleFonts.interTight(
            color: kColorPrimaryText,
            fontWeight: FontWeight.w600,
            fontSize: 24.0, // headlineSmall
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'If you have any questions about this Privacy Policy, please contact us:',
          style: GoogleFonts.inter(
            color: kColorSecondaryText,
            fontSize: 14.0, // bodyMedium
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16.0),
        _buildContactRow(
            icon: Icons.email_outlined, text: 'privacy@company.com'),
        const SizedBox(height: 8.0),
        _buildContactRow(
            icon: Icons.phone_outlined, text: '+1 (555) 123-4567'),
        const SizedBox(height: 8.0),
        _buildContactRow(
            icon: Icons.location_on_outlined,
            text: '123 Privacy Street, Data City, USA'),
      ],
    );
  }

  // Hàm trợ giúp cho một hàng liên hệ
  Widget _buildContactRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: kColorPrimary, size: 20),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: kColorPrimary, // Màu xanh lá
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}