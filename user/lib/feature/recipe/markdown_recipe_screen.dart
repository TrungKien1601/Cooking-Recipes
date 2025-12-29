import '../home/homepage_screen.dart';
import 'my_recipes_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import các màn hình khác
import 'add_recipe_screen.dart';
import '../home/settings_screen.dart';
import '../scan/pantry_screen.dart';
import 'blog_screen.dart'; // Import để chuyển sang màn hình chi tiết

// 👇 Import Service
import '../services/recipe_service.dart';

// --- Định nghĩa màu sắc ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorError = Color(0xFFFF5963);
const Color kColorRatingStar = Color(0xFFFFA726);
const Color kColorOverlay = Color(0x80000000);
const Color kColorShadow = Color(0x1A000000);

class MarkdownRecipeScreen extends StatefulWidget {
  const MarkdownRecipeScreen({super.key});

  @override
  State<MarkdownRecipeScreen> createState() => _MarkdownRecipeScreenState();
}

class _MarkdownRecipeScreenState extends State<MarkdownRecipeScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  final int _selectedIndex = 0; // Để highlight đúng tab nếu cần

  // ✅ Thay đổi: Dùng List dynamic để chứa dữ liệu thật từ API
  List<dynamic> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    
    // ✅ Gọi API lấy dữ liệu thật
    _fetchFavoriteRecipes();
  }

  // ✅ Hàm lấy dữ liệu từ API
  Future<void> _fetchFavoriteRecipes() async {
    setState(() => _isLoading = true);
    try {
      // Gọi Service lấy danh sách yêu thích
      // Lưu ý: Bạn cần đảm bảo RecipeService có hàm getFavoriteRecipes
      // Nếu chưa có, tạm thời mình dùng getAllRecipes để test hiển thị
      final result = await RecipeService.getFavoriteRecipes(); 
      
      if (result['success'] == true) {
        setState(() {
          _favoriteRecipes = result['data'] ?? [];
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách yêu thích: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String id) async {
    try {
      bool success = await RecipeService.toggleFavorite(id);
      // Nếu toggle trả về false (đã bỏ like) -> Xóa khỏi list hiện tại
      if (!success) {
        setState(() {
          _favoriteRecipes.removeWhere((recipe) => recipe['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích")),
        );
      }
    } catch (e) {
      print("Lỗi xóa: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: _buildAppBar(),
        body: SafeArea(
          top: true,
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildSearchBar(),
                      _buildRecipeList(),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kColorBackground,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      title: Text(
        'Công thức yêu thích',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 24.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: kColorPrimaryText),
          onPressed: _fetchFavoriteRecipes, // Nút làm mới
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: TextFormField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          hintStyle: GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14.0),
          filled: true,
          fillColor: kColorCard,
          prefixIcon: const Icon(Icons.search_rounded, color: kColorSecondaryText, size: 20.0),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_favoriteRecipes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32.0),
        alignment: Alignment.center,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80.0, color: kColorSecondaryText.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text(
              'Chưa có mục yêu thích',
              style: GoogleFonts.interTight(
                color: kColorPrimaryText,
                fontSize: 22.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Hãy thả tim các món ăn bạn thích để xem lại ở đây.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14.0),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _favoriteRecipes[index];
          
          // ✅ XỬ LÝ ẢNH: Ghép domain nếu là ảnh upload
          String imageUrl = recipe['image'] ?? '';
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
             imageUrl = '${RecipeService.domain}$imageUrl';
          }

          // Xử lý thông tin hiển thị
          String title = recipe['name'] ?? 'Món chưa đặt tên';
          String difficulty = recipe['difficulty'] ?? 'Dễ';
          String time = "${recipe['cookTimeMinutes'] ?? 30} phút";
          String details = "$difficulty • $time";
          String rating = "5.0"; // Tạm thời hardcode rating nếu chưa có

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () {
                 // Chuyển sang trang chi tiết
                 Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => BlogScreen(recipeData: recipe))
                 );
              },
              child: _buildFavoriteRecipeCard(
                id: recipe['_id'], // ID Mongo thường là _id
                imageUrl: imageUrl,
                title: title,
                details: details,
                // rating: rating
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteRecipeCard({
    required String id,
    required String imageUrl,
    required String title,
    required String details,
    // required String rating,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kColorCard,
        boxShadow: const [
          BoxShadow(blurRadius: 4.0, color: kColorShadow, offset: Offset(0.0, 2.0))
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 180.0,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 180.0,
                      color: kColorBorder,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: kColorSecondaryText),
                          SizedBox(height: 8),
                          Text("Không tải được ảnh", style: TextStyle(color: kColorSecondaryText))
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.9, -0.8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    width: 40.0,
                    height: 40.0,
                    decoration: const BoxDecoration(
                      color: kColorOverlay,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: kColorError, size: 20.0),
                      onPressed: () => _removeFavorite(id),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                    details,
                    style: GoogleFonts.inter(
                      color: kColorSecondaryText,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Row(
                  //   children: [
                  //     const Icon(Icons.star_rounded, color: kColorRatingStar, size: 16.0),
                  //     const SizedBox(width: 4.0),
                  //     Text(rating, style: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w500)),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Đang ở tab "My Recipe" hoặc "Favorite"
      type: BottomNavigationBarType.fixed,
      backgroundColor: kColorCard,
      selectedItemColor: kColorPrimary,
      unselectedItemColor: kColorSecondaryText,
      onTap: (int index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false);
            break;
          case 1:
            // Đang ở đây rồi, không làm gì
            break;
          case 2:
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddRecipeScreen()));
            break;
          case 3:
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PantryScreen()));
            break;
          case 4:
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()));
            break;
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Recipe'), // Đổi icon thành Favorite
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Plus'),
        BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ],
    );
  }
}