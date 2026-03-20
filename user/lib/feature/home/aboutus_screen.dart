import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Định nghĩa màu sắc (trích xuất từ theme) ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C); // Màu xanh lá chính
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorInfo = Colors.white; // Màu chữ trắng
const Color kColorOverlay = Color(0x4D000000); // Lớp phủ đen 30%

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),
                _buildHeaderImage(),
                const SizedBox(height: 32.0),
                _buildOurStorySection(),
                const SizedBox(height: 32.0),
                _buildOurValuesSection(),
                const SizedBox(height: 32.0),
              ],
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
        'About Us',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 32.0, // headlineLarge
        ),
      ),
    );
  }

  // Header Image
  Widget _buildHeaderImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: kColorSecondaryText, // Màu nền lót
          image: const DecorationImage(
            fit: BoxFit.cover,
            // Sửa lỗi: Dùng placeholder hợp lệ
            image: NetworkImage(
              'https://placehold.co/800x400/568C4C/FFFFFF?text=Our+Team',
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: kColorOverlay, // Lớp phủ đen 30%
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'About Us',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.interTight(
                    color: kColorInfo,
                    fontSize: 44.0, // displayMedium
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Building the future together',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: kColorInfo,
                      fontSize: 16.0, // bodyLarge
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

  // Phần "Our Story"
  Widget _buildOurStorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Story',
            style: GoogleFonts.interTight(
              color: kColorPrimaryText,
              fontSize: 28.0, // headlineMedium
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'Founded in 2025, we started with a simple idea: to make digital solutions accessible and impactful. Our journey has been one of passion, persistence, and partnership.',
            style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 16.0, // bodyLarge
              height: 1.5, // line-height
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Today, we serve thousands of customers worldwide, helping them achieve their goals with our innovative technology and dedicated support.',
            style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 16.0,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Phần "Our Values"
  Widget _buildOurValuesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Values',
            style: GoogleFonts.interTight(
              color: kColorPrimaryText,
              fontSize: 28.0, // headlineMedium
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24.0),
          _buildValueItem(
            icon: Icons.lightbulb_outlined,
            title: 'Innovation',
            subtitle:
                'We constantly push boundaries to find better solutions.',
          ),
          const SizedBox(height: 16.0),
          _buildValueItem(
            icon: Icons.favorite_outlined,
            title: 'Customer First',
            subtitle:
                'Every decision we make is guided by our customers\' needs.',
          ),
          const SizedBox(height: 16.0),
          _buildValueItem(
            icon: Icons.groups_outlined,
            title: 'Collaboration',
            subtitle:
                'We believe the best results come from working together.',
          ),
        ],
      ),
    );
  }

  // Hàm trợ giúp cho một mục "Value"
  Widget _buildValueItem(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: kColorPrimary,
            shape: BoxShape.circle,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Icon(icon, color: kColorInfo, size: 24),
          ),
        ),
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
                  fontSize: 18.0, // titleMedium
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: kColorSecondaryText,
                  fontSize: 14.0, // bodyMedium
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}