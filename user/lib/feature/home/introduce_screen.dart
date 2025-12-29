import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../auth/login_screen.dart';

// --- Định nghĩa màu sắc ---
const Color kOnboardingBackground = Color(0xFFFFFFFF);
const Color kOnboardingPrimaryText = Color(0xFF1A1A1A);
const Color kOnboardingSecondaryText = Color(0xFF6B6B6B);
const Color kOnboardingButtonRed = Color(0xFF568C4C);
const Color kOnboardingButtonBorder = Color(0xFFE0E0E0);
const Color kOnboardingIconBg = Color(0xFFF0F0F0);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Logic quay về trang đầu (hoặc chuyển sang Login tùy bạn)
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onLoginPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOnboardingBackground,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 2,
              backgroundColor: kOnboardingButtonBorder,
              color: kOnboardingButtonRed,
              minHeight: 2.0,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage1(context),
                  _buildPage2(context),
                ],
              ),
            ),
            _buildBottomControls(context),
          ],
        ),
      ),
    );
  }

  // --- HÀM XÂY DỰNG CÁC PHẦN CỦA TRANG ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kOnboardingBackground,
      elevation: 0,
      title: Text(
        'CookBook', // Tên App thường giữ nguyên tiếng Anh
        style: GoogleFonts.interTight(
          color: kOnboardingPrimaryText,
          fontWeight: FontWeight.bold,
          fontSize: 22.0,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: () {
              // Placeholder: language switching is disabled in this build
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Language'),
                  content: const Text('Language switching is disabled in this build.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.language, color: Colors.black),
            tooltip: 'Language',
          ),
        ),
      ],
    );
  }

  // Trang 1
  Widget _buildPage1(BuildContext context) {
    // Local fallback strings (AppLocalizations not available)
    const String onboardingTitle1 = 'Discover recipes from around the world';
    const String onboardingDesc1 = 'Find, save and cook delicious recipes tailored for you.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildPage1Grid(),
          const SizedBox(height: 32.0),
          Text(
            onboardingTitle1,
            textAlign: TextAlign.center,
            style: GoogleFonts.interTight(
              color: kOnboardingPrimaryText,
              fontSize: 26.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            onboardingDesc1,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: kOnboardingSecondaryText,
              fontSize: 16.0,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Trang 2
  Widget _buildPage2(BuildContext context) {
    // Local fallback strings
    const String onboardingTitle2 = 'Personalized meal recommendations';
    const String onboardingDesc2 = 'Get meal plans, nutrition info and step-by-step guides.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildPage2Grid(),
          Text(
            onboardingTitle2,
            
            textAlign: TextAlign.center,
            style: GoogleFonts.interTight(
              color: kOnboardingPrimaryText,
              fontSize: 26.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            onboardingDesc2,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: kOnboardingSecondaryText,
              fontSize: 16.0,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Thanh điều hướng dưới cùng
  Widget _buildBottomControls(BuildContext context) {
    const String loginLabel = 'Login';
    const String nextLabel = 'Next';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: _onLoginPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: kOnboardingButtonRed,
              side: const BorderSide(color: kOnboardingButtonBorder, width: 2.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
            ),
            child: Text(
              loginLabel, // local fallback
              style: GoogleFonts.inter(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          ElevatedButton(
            onPressed: _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: kOnboardingButtonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 48.0, vertical: 16.0),
              elevation: 2.0,
            ),
            child: Text(
              nextLabel,
              style: GoogleFonts.inter(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM TRỢ GIÚP TẠO LƯỚI (GRID) - GIỮ NGUYÊN ---
  
  Widget _buildPage1Grid() {
    Widget buildImage(String url, {double height = 120.0}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          url, height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height, color: kOnboardingIconBg,
            child: const Icon(Icons.broken_image, color: kOnboardingSecondaryText),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              buildImage('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=120&h=180&fit=crop'),
              const SizedBox(height: 11),
              buildImage('https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=120&h=120&fit=crop'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              buildImage('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=120&h=180&fit=crop'),
              const SizedBox(height: 11),
              buildImage('https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=120&h=180&fit=crop'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              buildImage('https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=120&h=180&fit=crop'),
              const SizedBox(height: 11),
              buildImage('https://images.unsplash.com/photo-1473093226795-af9932fe5856?w=120&h=120&fit=crop'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage2Grid() {
    Widget buildImage(String url, {double height = 120.0}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          url, height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height, color: kOnboardingIconBg,
            child: const Icon(Icons.broken_image, color: kOnboardingSecondaryText),
          ),
        ),
      );
    }

    Widget buildIcon(IconData icon, Color color, {double height = 120.0}) {
      return Container(
        height: height, width: double.infinity,
        decoration: BoxDecoration(color: kOnboardingIconBg, borderRadius: BorderRadius.circular(12.0)),
        child: Center(child: FaIcon(icon, color: color, size: 48.0)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              buildImage('https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=120&h=120&fit=crop'),
              const SizedBox(height: 11),
              buildIcon(FontAwesomeIcons.tiktok, Colors.black),
              const SizedBox(height: 11),
              buildImage('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=120&h=120&fit=crop'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              buildIcon(FontAwesomeIcons.instagram, Colors.purple),
              const SizedBox(height: 11),
              buildImage('https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=120&h=180&fit=crop'),
              const SizedBox(height: 11),
              buildIcon(FontAwesomeIcons.pinterest, Colors.red),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              buildImage('https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=120&h=180&fit=crop'),
              const SizedBox(height: 11),
              buildIcon(FontAwesomeIcons.facebook, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }
}