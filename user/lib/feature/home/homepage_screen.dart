import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// --- IMPORTS ---
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/util_service.dart';

// Screens
import '../auth/login_screen.dart';
import '../recipe/add_recipe_screen.dart';
import '../recipe/markdown_recipe_screen.dart';
import '../recipe/my_recipes_screen.dart';
import '../recipe/blog_screen.dart';
import '../scan/pantry_screen.dart';
import 'settings_screen.dart';
import 'filter_screen.dart';
import 'notifications_screen.dart';
import 'aboutus_screen.dart';
import 'contactus_screen.dart';

class HomePage extends StatefulWidget {
  // Biến nhận dữ liệu từ Survey (Giữ nguyên logic này để app mượt)
  final List<dynamic>? initialRecipes;
  final Map<String, dynamic>? nutritionData;
  final List<String>? suggestedMeals;

  const HomePage({
    super.key, 
    this.suggestedMeals,
    this.initialRecipes,
    this.nutritionData
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- CONTROLLERS ---
  late TextEditingController _searchController;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- SETTINGS ---
  final String baseUrl = RecipeService.domain;
  final AuthService _authService = AuthService();

  // --- STATE DATA ---
  String _currentAvatar = "";
  String _currentName = "Chef";
  int _selectedIndex = 0;

  List<dynamic> _aiRecommendations = [];
  List<dynamic> _allRecipes = [];

  bool _isLoadingInitial = true;
  bool _hasUnreadNotifications = false;
  String _searchQuery = "";
  Map<String, List<String>> _currentFilters = {};

  // --- COLORS ---
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = Colors.white;
  final Color primaryColor = const Color(0xFF568C4C);
  final Color secondaryText = const Color(0xFF57636C);
  final Color primaryText = const Color(0xFF15161E);
  final Color orangeAccent = const Color(0xFFFF6B35);
  final Color errorColor = const Color(0xFFFF5963);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _pageController = PageController(viewportFraction: 0.9); // Để lộ 1 chút card sau
    _initialDataLoad();
  }

  // ============================================================
  // 1. LOGIC TẢI DỮ LIỆU
  // ============================================================

  Future<void> _initialDataLoad() async {
    setState(() => _isLoadingInitial = true);

    await Future.wait([
      _loadUserProfile(),
      _checkUnreadNotifications(),
    ]);

    // Nếu có dữ liệu từ Survey truyền qua -> Dùng luôn
    if (widget.initialRecipes != null && widget.initialRecipes!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allRecipes = widget.initialRecipes!;
          _isLoadingInitial = false;
        });
      }
    } else {
      // Nếu không -> Tải từ API
      await _fetchAllRecipes();
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadUserProfile(),
      _fetchAllRecipes(),
      _checkUnreadNotifications(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileData = await _authService.getUserProfile();

      if (mounted && profileData != null) {
        setState(() {
          _currentName = profileData['username'] ?? profileData['name'] ?? "Chef";
          _currentAvatar = _formatImageUrl(profileData['image']);
          
          // Lấy danh sách gợi ý AI (có chứa bữa Sáng/Trưa/Chiều)
          _aiRecommendations = profileData['ai_meal_suggestions'] ?? [];
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_cache_name', _currentName);
        await prefs.setString('user_cache_avatar', _currentAvatar);
      } else {
        _loadFromCache();
      }
    } catch (e) {
      debugPrint("❌ Lỗi Load Profile: $e");
      _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentName = prefs.getString('user_cache_name') ?? "Chef";
        _currentAvatar = prefs.getString('user_cache_avatar') ?? "";
      });
    }
  }

  Future<void> _fetchAllRecipes() async {
    try {
      final result = await RecipeService.getAllRecipes(
        mealTimeTags: _currentFilters['mealTimeTags']?.join(','),
        dietTags: _currentFilters['dietTags']?.join(','),
        regionTags: _currentFilters['regionTags']?.join(','),
        dishtypeTags: _currentFilters['dishtypeTags']?.join(','),
      );

      if (mounted && result['success'] == true) {
        setState(() => _allRecipes = result['data'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Lỗi API Recipes: $e");
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final result = await RecipeService.getNotifications();
      if (result['success'] == true && mounted) {
        List<dynamic> notis = result['data'] ?? [];
        setState(() =>
            _hasUnreadNotifications = notis.any((n) => n['isRead'] == false));
      }
    } catch (e) {
      debugPrint("Lỗi Notification: $e");
    }
  }

  String _formatImageUrl(String? img) {
    if (img == null || img.isEmpty || img.contains('default')) return "";
    if (img.startsWith('http')) return img;
    String path = img.startsWith('/') ? img.substring(1) : img;
    return "$baseUrl/$path";
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ============================================================
  // UI BUILDERS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: primaryBackground,
        appBar: _buildAppBar(),
        endDrawer: _buildAppDrawer(),
        bottomNavigationBar: _buildBottomNav(),
        body: _isLoadingInitial
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                color: primaryColor,
                displacement: 40,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      if (widget.initialRecipes != null && widget.initialRecipes!.isNotEmpty)
                        _buildSurveyResultBanner(),
                        
                      _buildBanner(), // Banner AI (Đã sửa lại hiển thị bữa)
                      _buildSearchBar(),
                      _buildActionButtons(),
                      _buildRecipeList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSurveyResultBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Thực đơn được cá nhân hóa cho bạn",
              style: GoogleFonts.inter(
                  color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: _fetchAllRecipes, // Reload lại nếu muốn thoát chế độ lọc
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBackground,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primaryColor,
            backgroundImage: _currentAvatar.isNotEmpty
                ? NetworkImage(_currentAvatar)
                : const NetworkImage(
                    'https://images.unsplash.com/photo-1522075793577-0e6b86be585b?q=80&w=100'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào,',
                  style: GoogleFonts.inter(color: secondaryText, fontSize: 12)),
              Text(_currentName,
                  style: GoogleFonts.interTight(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
      actions: [
        _buildCircleIconButton(
          icon: _hasUnreadNotifications
              ? Icons.notifications_active
              : Icons.notifications_none,
          iconColor: _hasUnreadNotifications ? orangeAccent : primaryText,
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()));
            _checkUnreadNotifications();
          },
        ),
        const SizedBox(width: 8),
        _buildCircleIconButton(
          icon: Icons.menu,
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // --- PHẦN BANNER AI (ĐÃ SỬA LẠI) ---
  Widget _buildBanner() {
    if (_aiRecommendations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Thực đơn hôm nay (AI)",
                  style: GoogleFonts.interTight(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Icon(Icons.auto_awesome, color: orangeAccent),
            ],
          ),
        ),
        SizedBox(
          height: 220, // Giảm chiều cao chút cho cân đối
          child: PageView.builder(
            controller: _pageController,
            itemCount: _aiRecommendations.length,
            itemBuilder: (context, index) {
              final item = _aiRecommendations[index];
              return _buildAiCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiCard(dynamic item) {
    // 1. Lấy tên món và tên bữa (Sáng/Trưa/Tối)
    String foodName = "";
    String mealTime = "";

    if (item is String) {
      foodName = item;
      mealTime = "Gợi ý";
    } else {
      foodName = item['dishName'] ?? item['name'] ?? item['dish'] ?? "Món ngon";
      // Các key thường gặp cho bữa ăn từ AI
      mealTime = item['meal'] ?? item['time'] ?? item['buoi'] ?? "Gợi ý";
    }

    return FutureBuilder<String?>(
      future: UtilService.searchImage(foodName),
      builder: (context, snapshot) {
        // 2. FIX ẢNH: Thêm từ khóa 'cooked food dish photorealistic' để AI vẽ đúng món ăn
        String safeQuery = Uri.encodeComponent("$foodName cooked food dish photorealistic");
        String imgUrl = snapshot.data ?? "https://image.pollinations.ai/prompt/$safeQuery";

        return InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BlogScreen(recipeData: {
                        ...((item is Map) ? item : {}),
                        'image': imgUrl,
                        'name': foodName,
                        'description': "Gợi ý cho $mealTime"
                      }))),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8), // Margin nhỏ lại để PageView đẹp hơn
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                  image: NetworkImage(imgUrl), 
                  fit: BoxFit.cover,
                  // Thêm loadingBuilder để không bị nháy trắng
                  onError: (_, __) => const AssetImage('assets/images/placeholder_food.png') // Fallback nếu lỗi
              ),
              boxShadow: [
                 BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5)
                 )
              ]
            ),
            child: Stack(
              children: [
                // Gradient mờ bên dưới để chữ dễ đọc
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ]),
                  ),
                ),
                
                // 3. HIỂN THỊ TÊN MÓN (Góc dưới)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Text(foodName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),

                // 4. HIỂN THỊ BỮA ĂN (Sáng/Trưa/Tối) - Góc trên trái
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                         BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ]
                    ),
                    child: Text(
                      mealTime.toUpperCase(), // VIẾT HOA BỮA ĂN
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- HẾT PHẦN BANNER AI ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextFormField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Tìm món ăn...',
          filled: true,
          fillColor: secondaryBackground,
          prefixIcon: Icon(Icons.search, color: secondaryText),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            accountName: Text(_currentName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundImage: _currentAvatar.isNotEmpty
                  ? NetworkImage(_currentAvatar)
                  : const NetworkImage(
                      'https://images.unsplash.com/photo-1522075793577-0e6b86be585b?q=80&w=100'),
            ),
          ),
          _buildDrawerItem(Icons.settings_outlined, "Cài đặt", () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()));
            _loadUserProfile();
          }),
          _buildDrawerItem(
              Icons.info_outline,
              "Về chúng tôi",
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AboutUsScreen()))),
          _buildDrawerItem(
              Icons.contact_support_outlined,
              "Liên hệ",
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactUsScreen()))),
          const Divider(),
          _buildDrawerItem(Icons.logout, "Đăng xuất", _handleLogout,
              color: errorColor),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      showUnselectedLabels: true,
      onTap: (i) {
        if (i == 0) return;

        Widget nextScreen;
        switch (i) {
          case 1:
            nextScreen = const MyRecipeScreen();
            break;
          case 2:
            nextScreen = const AddRecipeScreen();
            break;
          case 3:
            nextScreen = const PantryScreen();
            break;
          case 4:
            nextScreen = const SettingsScreen();
            break;
          default:
            return;
        }

        Navigator.push(context,
                MaterialPageRoute(builder: (context) => nextScreen))
            .then((_) {
          if (i == 2 || i == 4) _handleRefresh();
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Của tôi'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40, color: Color(0xFF568C4C)),
            label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Tủ lạnh'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
      ],
    );
  }

  Widget _buildCircleIconButton(
      {required IconData icon, Color? iconColor, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: secondaryBackground, borderRadius: BorderRadius.circular(12)),
      child: IconButton(
          icon: Icon(icon, color: iconColor ?? primaryText, size: 24),
          onPressed: onTap),
    );
  }

  Widget _buildActionButtons() {
    bool isFilterActive = _currentFilters.values.any((l) => l.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildSquareBtn(
              icon: Icons.filter_list,
              color: isFilterActive ? primaryColor : null,
              onTap: () async {
                final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FilterScreen(currentFilters: _currentFilters)));
                if (res != null) {
                  setState(() => _currentFilters = res);
                  _fetchAllRecipes();
                }
              }),
          const SizedBox(width: 12),
          _buildSquareBtn(
              icon: Icons.bookmark_border,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MarkdownRecipeScreen()))),
        ],
      ),
    );
  }

  Widget _buildSquareBtn(
      {required IconData icon, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
            color: secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: color ?? const Color(0xFFE0E3E7),
                width: color != null ? 2 : 1)),
        child: Icon(icon, color: primaryText),
      ),
    );
  }

  Widget _buildRecipeList() {
    final filtered = _allRecipes
        .where((r) => (r['name'] ?? r['title'] ?? "")
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
              child: Text("Không tìm thấy món ăn",
                  style: GoogleFonts.inter(color: secondaryText))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length + 1,
      itemBuilder: (context, i) {
        if (i == 0)
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("Cộng đồng chia sẻ",
                  style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryText)));
        final recipe = filtered[i - 1];
        String img = _formatImageUrl(recipe['image']);

        return InkWell(
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BlogScreen(recipeData: {...recipe, 'image': img})))
              .then((_) => _fetchAllRecipes()),
          child: _buildRecipeCard(
            imageUrl: img,
            title: recipe['name'] ?? "Chưa đặt tên",
            description: recipe['description'] ?? "Món ngon mỗi ngày",
            time: recipe['cookTimeMinutes'] != null
                ? "${recipe['cookTimeMinutes']} phút"
                : (recipe['time'] ?? "30 phút"),
            servings: "${recipe['servings'] ?? 2} người",
            isSaved: recipe['isSaved'] ?? recipe['isFavorite'] ?? false,
            onBookmark: () async {
              String id = recipe['_id'] ?? recipe['id'];
              final result = await RecipeService.toggleSave(id);
              if (mounted && result['success'] == false) {
                bool isSavedNow = result['isSaved'] ?? false;
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isSavedNow ? "Đã lưu!" : "Đã bỏ lưu",
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: isSavedNow ? primaryColor : secondaryText,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ));
                _fetchAllRecipes(); // Refresh để update icon
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
        leading: Icon(icon, color: color ?? secondaryText),
        title: Text(title, style: TextStyle(color: color ?? primaryText)),
        onTap: onTap);
  }

  Widget _buildRecipeCard(
      {required String imageUrl,
      required String title,
      required String description,
      required String time,
      required String servings,
      required bool isSaved,
      required VoidCallback onBookmark}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0x1A000000),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)))),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.interTight(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: secondaryText, fontSize: 12)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.access_time, size: 16, color: orangeAccent),
            const SizedBox(width: 4),
            Text(time, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.people_outline,
                size: 16, color: Color(0xFF4FB239)),
            const SizedBox(width: 4),
            Text(servings, style: const TextStyle(fontSize: 12)),
          ]),
          IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? primaryColor : secondaryText),
              onPressed: onBookmark),
        ])
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}