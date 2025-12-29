import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../recipe/add_recipe_screen.dart';
import 'settings_screen.dart';
import '../recipe/markdown_recipe_screen.dart'; // Màn hình Bookmark (Favorite)
import '../recipe/my_recipes_screen.dart';
import 'filter_screen.dart';
import '../auth/login_screen.dart';
import '../scan/pantry_screen.dart';
import 'notifications_screen.dart'; // ✅ Import màn hình thông báo
import 'aboutus_screen.dart';
import 'contactus_screen.dart';
import '../recipe/blog_screen.dart';
import '../services/recipe_service.dart'; // Import service

class HomePage extends StatefulWidget {
  final List<String>? suggestedMeals;

  const HomePage({
    super.key,
    this.suggestedMeals,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late PageController _pageController;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- CẤU HÌNH SERVER ---
  // Lưu ý: Đảm bảo domain này khớp với RecipeService
  final String baseUrl = RecipeService.domain;

  // --- CẤU HÌNH GOOGLE SEARCH API ---
  final String _googleApiKey = "AIzaSyAksWw3AwgHO7SaQw5bQZZDBkGQh_4G-88"; // Lưu ý bảo mật key này
  final String _googleCxId = "81194332729ef486f";

  // Cache tạm để lưu link ảnh đã tìm được
  final Map<String, String> _imageCache = {};

  // --- DỮ LIỆU USER ---
  String _currentAvatar = "";
  String _currentName = "Chef";

  // Dữ liệu API
  List<dynamic> _aiRecommendations = [];
  List<dynamic> _allRecipes = [];
  bool _isLoadingAi = true;
  bool _isLoadingRecipes = true;

  // ✅ BIẾN MỚI: Trạng thái thông báo chưa đọc
  bool _hasUnreadNotifications = false;

  // Biến lọc & UI
  String _searchQuery = "";
  String _selectedCategory = "All";

  // Colors
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = Colors.white;
  final Color primaryColor = const Color(0xFF568C4C);
  final Color secondaryText = const Color(0xFF57636C);
  final Color primaryText = const Color(0xFF15161E);
  final Color alternateBorder = const Color(0xFFE0E3E7);
  final Color errorColor = const Color(0xFFFF5963);
  final Color successColor = const Color(0xFF4FB239);
  final Color orangeAccent = const Color(0xFFFF6B35);
  final Color shadowColor = const Color(0x1A000000);

  // Card Background (định nghĩa thêm nếu thiếu)
  final Color kCardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _pageController = PageController();

    _loadUserData();
    _fetchAllRecipes();

    // ✅ Kiểm tra thông báo ngay khi mở app
    _checkUnreadNotifications();

    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchAiSuggestions();
    });
  }

  // ✅ HÀM: Kiểm tra thông báo chưa đọc
  Future<void> _checkUnreadNotifications() async {
    try {
      final result = await RecipeService.getNotifications();
      if (result['success'] == true && result['data'] != null) {
        List<dynamic> notifications = result['data'];
        // Nếu có bất kỳ thông báo nào mà isRead == false -> Hiện chấm đỏ
        bool hasUnread = notifications.any((n) => n['isRead'] == false);

        if (mounted) {
          setState(() {
            _hasUnreadNotifications = hasUnread;
          });
        }
      }
    } catch (e) {
      print("⚠️ Lỗi kiểm tra thông báo: $e");
    }
  }

  // ✅ [FIXED] Load User Data: Sửa fullName -> username
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final data = jsonDecode(userDataString);
      if (mounted) {
        setState(() {
          // Ưu tiên 'username', nếu không có thì lấy 'name' (Google), cuối cùng là 'Chef'
          _currentName = data['username'] ?? data['name'] ?? "Chef";
          
          String? img = data['image'];

          if (img != null && img.isNotEmpty && !img.contains('default')) {
            if (img.startsWith('http')) {
              _currentAvatar = img;
            } else {
              String path = img;
              if (path.startsWith('/')) path = path.substring(1);
              _currentAvatar = "$baseUrl/$path?t=${DateTime.now().millisecondsSinceEpoch}";
            }
          } else {
            _currentAvatar = "";
          }
        });
      }
    }
  }

  // ✅ [FIXED] Fetch AI & Update Profile: Sửa fullName -> username
  Future<void> _fetchAiSuggestions() async {
    setState(() => _isLoadingAi = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        String? userDataString = prefs.getString('user_data');
        if (userDataString != null) {
          final data = jsonDecode(userDataString);
          userId = data['_id'] ?? data['id'];
        }
      }

      if (userId != null) {
        final authService = AuthService();
        final profileData = await authService.getUserProfile(userId);

        if (mounted && profileData != null) {
          setState(() {
            _aiRecommendations = profileData['ai_meal_suggestions'] ?? [];
            _isLoadingAi = false;
            
            // Cập nhật lại avatar từ profile mới nhất nếu có
            if (profileData['image'] != null) {
               String img = profileData['image'];
               if (img.startsWith('http')) {
                  _currentAvatar = img;
               } else {
                  String path = img.startsWith('/') ? img.substring(1) : img;
                  _currentAvatar = "$baseUrl/$path?t=${DateTime.now().millisecondsSinceEpoch}";
               }
            }
            // Cập nhật tên mới nhất (Ưu tiên username)
            if (profileData['username'] != null) {
               _currentName = profileData['username'];
            } else if (profileData['fullName'] != null) {
               // Fallback nếu backend trong tương lai đổi ý dùng fullName
               _currentName = profileData['fullName'];
            }
          });
        }
      } else {
        setState(() => _isLoadingAi = false);
      }
    } catch (e) {
      debugPrint("❌ Lỗi tải gợi ý AI: $e");
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  Future<String> _fetchRealImage(String query) async {
    if (_imageCache.containsKey(query)) {
      return _imageCache[query]!;
    }

    final String searchUrl =
        "https://www.googleapis.com/customsearch/v1?q=$query vietnamese food dish&cx=$_googleCxId&key=$_googleApiKey&searchType=image&num=1&imgSize=large";

    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          String realUrl = data['items'][0]['link'];
          _imageCache[query] = realUrl;
          return realUrl;
        }
      }
    } catch (e) {
      debugPrint("Lỗi Google API Exception: $e");
    }

    // Fallback AI Image nếu Google API lỗi hoặc hết quota
    String aiUrl =
        "https://image.pollinations.ai/prompt/${Uri.encodeComponent(query)}%20vietnamese%20food%20photorealistic";
    _imageCache[query] = aiUrl;
    return aiUrl;
  }

  Future<void> _fetchAllRecipes() async {
    setState(() => _isLoadingRecipes = true);

    try {
      final result = await RecipeService.getAllRecipes();

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _allRecipes = result['data'] ?? [];
          } else {
            print("⚠️ Lỗi server: ${result['message']}");
          }
        });
      }
    } catch (e) {
      print("❌ Lỗi Crash Home: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecipes = false);
      }
    }
  }

  Future<void> _handleToggleFavorite(String recipeId, int index) async {
    try {
      // 1. Gọi API toggle
      bool newStatus = await RecipeService.toggleFavorite(recipeId);

      // 2. Cập nhật lại trạng thái trong danh sách _allRecipes để UI đổi màu tim ngay lập tức
      setState(() {
        _allRecipes[index]['isFavorite'] = newStatus;
      });

      // 3. Thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "Đã thêm vào yêu thích ❤️" : "Đã bỏ yêu thích 💔"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Lỗi toggle favorite: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: primaryBackground,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
        endDrawer: _buildAppDrawer(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryBackground,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 45.0,
            height: 45.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2.0),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: _currentAvatar.isNotEmpty
                    ? NetworkImage(_currentAvatar)
                    : const NetworkImage(
                        'https://images.unsplash.com/photo-1522075793577-0e6b86be585b?ixlib=rb-4.1.0&q=80&w=1080'),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào Mừng ',
                  style: GoogleFonts.inter(color: secondaryText, fontSize: 12.0)),
              Text(_currentName, // Đã fix logic lấy tên
                  style: GoogleFonts.interTight(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.0)),
            ],
          ),
        ],
      ),
      actions: [
        // ✅ NÚT THÔNG BÁO (NOTIFICATION)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () async {
              // Chuyển sang màn hình thông báo
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
              // Khi quay về, kiểm tra lại xem user đã đọc chưa để tắt chấm đỏ
              _checkUnreadNotifications();
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: secondaryBackground,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: primaryText, size: 24.0),

                  // 🔴 CHẤM ĐỎ (BADGE)
                  if (_hasUnreadNotifications)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: errorColor, // Màu đỏ
                          shape: BoxShape.circle,
                          border: Border.all(color: secondaryBackground, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // NÚT MENU (DRAWER)
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            decoration: BoxDecoration(
                color: secondaryBackground,
                borderRadius: BorderRadius.circular(12.0)),
            child: IconButton(
              icon: Icon(Icons.menu, color: primaryText, size: 24.0),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: secondaryBackground,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryText,
      onTap: (int index) async {
        if (index == _selectedIndex) return;
        switch (index) {
          case 0:
            setState(() => _selectedIndex = index);
            break;
          case 1:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyRecipeScreen()));
            break;
          case 2:
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddRecipeScreen())
              );
              if (result == true) {
                print("🔄 Đang làm mới trang chủ...");
                _fetchAllRecipes();
                setState(() => _selectedIndex = 0);
              }
            break;
          case 3:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const PantryScreen()));
            break;
          case 4:
            await Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()));
            _loadUserData();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Recipe'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 36.0), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ],
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentName,
                style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            accountEmail: const Text(''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _currentAvatar.isNotEmpty
                  ? NetworkImage(_currentAvatar)
                  : const NetworkImage(
                      'https://images.unsplash.com/photo-1522075793577-0e6b86be585b?ixlib=rb-4.1.0&q=80&w=1080'),
              backgroundColor: Colors.white,
            ),
            decoration: BoxDecoration(color: primaryColor),
          ),
          ListTile(
              leading: Icon(Icons.add_circle_outline, color: secondaryText),
              title: Text('Add Recipe',
                  style: GoogleFonts.inter(color: primaryText)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AddRecipeScreen()))),
          ListTile(
              leading: Icon(Icons.kitchen, color: secondaryText),
              title: Text('Pantry', style: GoogleFonts.inter(color: primaryText)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PantryScreen()))),
          ListTile(
              leading: Icon(Icons.bookmark_border, color: secondaryText),
              title: Text('Bookmark', style: GoogleFonts.inter(color: primaryText)),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MarkdownRecipeScreen()))),
          const Divider(),
          ListTile(
              leading: Icon(Icons.settings_outlined, color: secondaryText),
              title: Text('Settings', style: GoogleFonts.inter(color: primaryText)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()));
                _loadUserData();
              }),
          ListTile(
              leading: Icon(Icons.info_outline, color: secondaryText),
              title: Text('About Us', style: GoogleFonts.inter(color: primaryText)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutUsScreen()))),
          ListTile(
              leading: Icon(Icons.notifications_outlined, color: secondaryText),
              title:
                  Text('Notification', style: GoogleFonts.inter(color: primaryText)),
              onTap: () async {
                 Navigator.pop(context); // Đóng drawer trước
                 await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()));
                 _checkUnreadNotifications();
              }),
          ListTile(
              leading: Icon(Icons.contact_mail_outlined, color: secondaryText),
              title:
                  Text('Contact Us', style: GoogleFonts.inter(color: primaryText)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ContactUsScreen()))),
          const Divider(),
          ListTile(
              leading: Icon(Icons.logout_outlined, color: errorColor),
              title: Text('Logout', style: GoogleFonts.inter(color: errorColor)),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildBanner(),
            _buildSearchBar(),
            _buildActionButtons(),
            _buildRecipeList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    if (_isLoadingAi) {
      return Container(
          height: 260,
          margin: const EdgeInsets.all(20),
          child: const Center(child: CircularProgressIndicator()));
    }
    if (_aiRecommendations.isEmpty) {
      return Container(
          height: 100,
          margin: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Text("Chưa có gợi ý nào.",
              style: GoogleFonts.inter(color: secondaryText)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Gợi ý cho bạn (AI)",
                  style: GoogleFonts.interTight(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: primaryText)),
              Icon(Icons.auto_awesome, color: orangeAccent),
            ],
          ),
        ),
        SizedBox(
          height: 260.0,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _aiRecommendations.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(_aiRecommendations[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(dynamic item) {
    final String foodName = item['name']?.toString() ?? "Món ngon";
    final String time = item['time']?.toString() ?? "30p";
    final String calories = "${item['calories']?.toString() ?? '0'} Kcal";

    return FutureBuilder<String>(
      future: _fetchRealImage(foodName),
      builder: (context, snapshot) {
        String imageUrl =
            snapshot.data ?? "https://via.placeholder.com/400x300?text=Loading...";
        bool isLoaded = snapshot.hasData && snapshot.data != null;

        return InkWell(
          onTap: () {
            final Map<String, dynamic> dataToSend = {
              ...item,
              'image': imageUrl,
              'description': item['description'] ??
                  "Món ăn gợi ý được cá nhân hóa bởi AI.",
              'ingredients':
                  item['ingredients'] is List ? item['ingredients'] : [],
              'instructions':
                  item['instructions'] is List ? item['instructions'] : [],
            };

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BlogScreen(
                          recipeData: dataToSend,
                        )));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: isLoaded
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, loading) => loading == null
                              ? child
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator())),
                          errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image)),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(item['session'] ?? "Suggestion",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10))),
                      const SizedBox(height: 8),
                      Text(foodName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.interTight(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.timer, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(time,
                            style:
                                const TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 16),
                        const Icon(Icons.local_fire_department,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(calories,
                            style:
                                const TextStyle(color: Colors.white, fontSize: 12))
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() {
          _searchQuery = value;
        }),
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          filled: true,
          fillColor: secondaryBackground,
          prefixIcon: Icon(Icons.search, color: secondaryText),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Row(
        children: [
          _buildActionButton(
              icon: Icons.filter_list,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FilterScreen()))),
          const SizedBox(width: 12.0),
          _buildActionButton(
              icon: Icons.bookmark_border,
              borderColor: primaryText,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MarkdownRecipeScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, Color? borderColor, required VoidCallback onTap}) {
    return Container(
      width: 80.0,
      height: 80.0,
      decoration: BoxDecoration(
          color: secondaryBackground,
          borderRadius: BorderRadius.circular(20.0),
          border: borderColor != null
              ? Border.all(color: borderColor)
              : Border.all(color: alternateBorder)),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Icon(icon, color: primaryText, size: 30.0)),
    );
  }

  Widget _buildRecipeList() {
    if (_isLoadingRecipes) {
      return const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()));
    }

    final filteredRecipes = _allRecipes.where((recipe) {
      final title = recipe['name'] ?? recipe['title'] ?? "";
      final matchSearch = title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory =
          _selectedCategory == "All" || recipe['category'] == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 20.0, 0, 100.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRecipes.length + 1, // +1 cho tiêu đề
      itemBuilder: (context, i) {
        if (i == 0) {
           return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text("Cộng đồng chia sẻ",
                style: GoogleFonts.interTight(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: primaryText)));
        }

        final recipe = filteredRecipes[i - 1]; // Trừ 1 vì index 0 là title
        
        // Tìm index thực tế trong list gốc để update state
        final realIndex = _allRecipes.indexOf(recipe); 

        String rawImage = recipe['image'] ?? "";
        String fullImageUrl = "";
        if (rawImage.startsWith("http")) {
           fullImageUrl = rawImage;
        } else if (rawImage.isNotEmpty) {
           String path = rawImage.startsWith('/') ? rawImage : "/$rawImage";
           fullImageUrl = "$baseUrl$path"; 
        } else {
           fullImageUrl = "https://via.placeholder.com/400x300?text=No+Image";
        }

        return Column(
          children: [
            InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BlogScreen(
                            recipeData: {
                              ...recipe,
                              'image': fullImageUrl,
                            }))).then((_) {
                              // Khi quay lại từ BlogScreen, load lại list để cập nhật like/view
                              _fetchAllRecipes(); 
                            }),
              child: _buildRecipeCard(
                imageUrl: fullImageUrl,
                title: recipe['name'] ?? recipe['title'] ?? "Chưa đặt tên",
                description: recipe['description'] ?? "Không có mô tả",
                time: recipe['cookTimeMinutes'] != null
                    ? "${recipe['cookTimeMinutes']} phút"
                    : (recipe['time'] ?? "30 phút"),
                servings: "${recipe['servings'] ?? 2} người",
                isFavorite: recipe['isFavorite'] ?? false,
                // 👇 QUAN TRỌNG: Truyền hàm xử lý tim vào đây
                onFavoritePressed: () {
                   String id = recipe['_id'] ?? recipe['id'];
                   _handleToggleFavorite(id, realIndex);
                },
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(
      {required String imageUrl,
      required String title,
      required String description,
      required String time,
      required String servings,
      required bool isFavorite,
      required VoidCallback onFavoritePressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
            color: secondaryBackground,
            boxShadow: [
              BoxShadow(
                  blurRadius: 8.0, color: shadowColor, offset: const Offset(0.0, 2.0))
            ],
            borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(imageUrl,
                    width: double.infinity,
                    height: 180.0,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood))),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(title,
                      style: GoogleFonts.interTight(
                          color: primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 18.0))),
              Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(description,
                      style: GoogleFonts.inter(
                          color: secondaryText, fontSize: 12.0))),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.schedule, color: orangeAccent, size: 16.0),
                      const SizedBox(width: 8.0),
                      Text(time,
                          style: GoogleFonts.inter(
                              color: secondaryText, fontSize: 12.0)),
                      const SizedBox(width: 12.0),
                      Icon(Icons.people, color: successColor, size: 16.0),
                      const SizedBox(width: 8.0),
                      Text("$servings servings",
                          style: GoogleFonts.inter(
                              color: secondaryText, fontSize: 12.0))
                    ]),
                    Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: BoxDecoration(
                            color: kCardBackground, shape: BoxShape.circle),
                        child: IconButton(
                            icon: Icon(
                                isFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: primaryColor,
                                size: 18.0),
                            onPressed: onFavoritePressed
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}