import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart'; // Import Service
// Import các màn hình khác để điều hướng BottomNav
import '../home/homepage_screen.dart'; 
import 'add_recipe_screen.dart';
import 'my_recipes_screen.dart';
import '../scan/pantry_screen.dart';
import '../home/settings_screen.dart';
import 'blog_screen.dart'; // Để bấm vào xem chi tiết

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

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  late TextEditingController _searchController;
  // Index này tùy thuộc vào vị trí bạn đặt FavoriteScreen trong BottomNav
  // Giả sử bạn thay thế vị trí của MyRecipe (index 1) hoặc tạo tab riêng
  final int _selectedIndex = 1; 

  // State dữ liệu thật
  List<dynamic> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadFavorites(); // Gọi hàm tải dữ liệu
  }

  // ✅ Hàm tải dữ liệu từ API (Đã sửa logic mới)
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      // Gọi API lấy danh sách yêu thích trực tiếp
      final res = await RecipeService.getFavoriteRecipes();
      
      if (mounted) {
        setState(() {
          if (res['success'] == true && res['data'] != null) {
             _favoriteRecipes = res['data'];
          } else {
             _favoriteRecipes = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải yêu thích: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Hàm xóa favorite (Gọi API toggle)
  Future<void> _removeFavorite(String id) async {
    try {
      // Gọi API toggle (khi đang like mà gọi toggle -> sẽ thành dislike/bỏ like)
      bool isLiked = await RecipeService.toggleFavorite(id);
      
      // Nếu server trả về false (đã bỏ like), ta xóa khỏi list UI
      if (!isLiked) {
        setState(() {
          _favoriteRecipes.removeWhere((recipe) => (recipe['_id'] ?? recipe['id']) == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích")),
        );
      }
    } catch (e) {
      print("Lỗi xóa favorite: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
            : RefreshIndicator(
                onRefresh: _loadFavorites,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      _buildRecipeList(),
                      const SizedBox(height: 80), // Padding bottom cho list
                    ],
                  ),
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
      elevation: 0.0,
      automaticallyImplyLeading: false, // Tắt nút back mặc định nếu dùng BottomNav
      title: Text(
        'Món ăn yêu thích',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 24.0,
        ),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh, color: kColorPrimaryText),
            onPressed: _loadFavorites,
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm món ăn đã lưu...',
          hintStyle: GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14.0),
          filled: true,
          fillColor: kColorCard,
          prefixIcon: const Icon(Icons.search_rounded, color: kColorSecondaryText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
        ),
        onChanged: (value) {
           // Logic filter local nếu muốn (bạn tự implement)
        },
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_favoriteRecipes.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80.0, color: kColorSecondaryText.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text('Chưa có món yêu thích', style: GoogleFonts.interTight(color: kColorPrimaryText, fontSize: 20.0, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8.0),
            Text('Hãy thả tim các món ăn ngon nhé!', style: GoogleFonts.inter(color: kColorSecondaryText)),
          ],
        ),
      );
    }

    // Filter theo search query (Local filter)
    final filterText = _searchController.text.toLowerCase();
    final displayList = _favoriteRecipes.where((recipe) {
       final name = (recipe['name'] ?? '').toString().toLowerCase();
       return name.contains(filterText);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final recipe = displayList[index];
          
          // Map dữ liệu từ API sang UI
          final String id = recipe['_id'] ?? recipe['id'] ?? '';
          final String name = recipe['name'] ?? 'Món ăn';
          
          String image = recipe['image'] ?? '';
          if (image.isNotEmpty && !image.startsWith('http')) {
             image = '${RecipeService.domain}$image';
          }

          final String difficulty = recipe['difficulty'] ?? 'Dễ';
          final int time = recipe['cookTimeMinutes'] ?? recipe['time'] ?? 30;
          
          // Xử lý thông tin hiển thị
          final String details = "$difficulty • $time phút";

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              // Bấm vào thẻ để xem chi tiết
              onTap: () {
                // Thêm isFavorite: true vào data để BlogScreen hiển thị tim đỏ ngay
                final dataToSend = {...recipe, 'isFavorite': true};
                
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => BlogScreen(recipeData: dataToSend, isOwner: false)
                )).then((_) => _loadFavorites()); // Reload khi quay lại phòng khi user bỏ like ở màn chi tiết
              },
              child: _buildFavoriteRecipeCard(
                id: id,
                imageUrl: image,
                title: name,
                details: details,
                rating: "5.0", 
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
    required String rating,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kColorCard,
        boxShadow: const [BoxShadow(blurRadius: 4.0, color: kColorShadow, offset: Offset(0.0, 2.0))],
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
                      width: double.infinity, height: 180.0, color: kColorBorder,
                      child: const Icon(Icons.broken_image, color: kColorSecondaryText),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.9, -0.8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(color: kColorOverlay, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: kColorError, size: 20.0),
                      onPressed: () => _removeFavorite(id),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.interTight(color: kColorPrimaryText, fontWeight: FontWeight.w600, fontSize: 18.0)),
                  const SizedBox(height: 4.0),
                  Text(details, style: GoogleFonts.inter(color: kColorSecondaryText, fontSize: 12.0)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: kColorRatingStar, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text(rating, style: GoogleFonts.inter(fontSize: 12.0, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      const Icon(Icons.check_circle, color: kColorPrimary, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text("Đã lưu", style: GoogleFonts.inter(color: kColorPrimary, fontSize: 12.0)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Nav Bar giống Home (Để dễ điều hướng)
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex, // Tab Yêu thích/My Recipe
      type: BottomNavigationBarType.fixed,
      backgroundColor: kColorCard,
      selectedItemColor: kColorPrimary,
      unselectedItemColor: kColorSecondaryText,
      onTap: (int index) {
        if (index == _selectedIndex) return;
        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false);
            break;
          case 1:
            // Đang ở đây (Hoặc chuyển về MyRecipeScreen nếu Favorite là trang riêng)
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyRecipeScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRecipeScreen()));
            break;
          case 3:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantryScreen()));
            break;
          case 4:
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            break;
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Recipe'), 
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Plus'),
        BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ],
    );
  }
}