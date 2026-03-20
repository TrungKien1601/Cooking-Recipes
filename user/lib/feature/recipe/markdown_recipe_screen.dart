import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart'; // Import Service
// Import các màn hình khác
import '../home/homepage_screen.dart';
import 'add_recipe_screen.dart';
import 'my_recipes_screen.dart';
import '../scan/pantry_screen.dart';
import '../home/settings_screen.dart';
import '../recipe/blog_screen.dart';

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
  final int _selectedIndex = 1;

  // State dữ liệu
  List<dynamic> _savedRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadSavedRecipes();
  }

  // ✅ Hàm tải dữ liệu: getSavedRecipes
  Future<void> _loadSavedRecipes() async {
    setState(() => _isLoading = true);
    try {
      final res = await RecipeService.getSavedRecipes();

      if (mounted) {
        setState(() {
          if (res['success'] == true && res['data'] != null) {
            _savedRecipes = res['data'];
          } else {
            _savedRecipes = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách đã lưu: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Hàm xóa khỏi danh sách: toggleSave
  Future<void> _removeSavedRecipe(String id) async {
    try {
      final result = await RecipeService.toggleSave(id);

      // Nếu server trả về isSaved: false, tức là đã bỏ lưu thành công
      if (result['success'] == true && result['isSaved'] == false) {
        setState(() {
          _savedRecipes
              .removeWhere((recipe) => (recipe['_id'] ?? recipe['id']) == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa khỏi danh sách đã lưu")),
        );
      }
    } catch (e) {
      print("Lỗi xóa saved recipe: $e");
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
              ? const Center(
                  child: CircularProgressIndicator(color: kColorPrimary))
              : RefreshIndicator(
                  onRefresh: _loadSavedRecipes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildRecipeList(),
                        const SizedBox(height: 80),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: kColorPrimaryText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Bộ Sưu Tập',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 24.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: kColorPrimaryText),
          onPressed: _loadSavedRecipes,
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
          hintText: 'Tìm công thức đã lưu...',
          hintStyle:
              GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14.0),
          filled: true,
          fillColor: kColorCard,
          prefixIcon:
              const Icon(Icons.search_rounded, color: kColorSecondaryText),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide.none),
        ),
        onChanged: (value) => setState(() {}), // Re-build để filter local
      ),
    );
  }

  Widget _buildRecipeList() {
    if (_savedRecipes.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border,
                size: 80.0, color: kColorSecondaryText.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text('Chưa lưu món nào',
                style: GoogleFonts.interTight(
                    color: kColorPrimaryText,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8.0),
            Text('Hãy lưu lại các công thức bạn thích nhé!',
                style: GoogleFonts.inter(color: kColorSecondaryText)),
          ],
        ),
      );
    }

    // Filter Local
    final filterText = _searchController.text.toLowerCase();
    final displayList = _savedRecipes.where((recipe) {
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

          // Lấy ID chuẩn để BlogScreen dùng gọi API chi tiết
          final String id = recipe['_id'] ?? recipe['id'] ?? '';
          final String name = recipe['name'] ?? 'Món ăn';

          // --- XỬ LÝ ẢNH FULL URL ---
          String image = recipe['image'] ?? '';
          if (image.isNotEmpty && !image.startsWith('http')) {
            if (!image.startsWith('/')) {
              image = '${RecipeService.domain}/$image';
            } else {
              image = '${RecipeService.domain}$image';
            }
          }

          final String difficulty = recipe['difficulty'] ?? 'Dễ';
          final int time = recipe['cookTimeMinutes'] ?? recipe['time'] ?? 30;
          final String details = "$difficulty • $time phút";

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () {
                // 🔥 LOGIC QUAN TRỌNG NHẤT Ở ĐÂY
                final dataToSend = {
                  // 1. Copy toàn bộ dữ liệu hiện có (dù thiếu)
                  ...recipe,

                  // 2. Ghi đè các trường quan trọng đã xử lý
                  '_id': id, // Đảm bảo ID chính xác
                  'image': image, // URL ảnh đã nối domain
                  'isSaved': true, // Đánh dấu đã lưu

                  // 3. Fallback giá trị rỗng để UI không bị crash trước khi load xong
                  'description': recipe['description'] ?? "",
                  'ingredients': recipe['ingredients'] ?? [],
                  'steps': recipe['steps'] ?? recipe['instructions'] ?? [],
                };

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        // BlogScreen mới sẽ tự động dùng '_id' để tải full data
                        builder: (context) => BlogScreen(
                            recipeData: dataToSend, isOwner: false))).then(
                    (_) => _loadSavedRecipes()); // Reload khi quay lại
              },
              child: _buildSavedRecipeCard(
                id: id,
                imageUrl: image,
                title: name,
                details: details,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedRecipeCard({
    required String id,
    required String imageUrl,
    required String title,
    required String details,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kColorCard,
        boxShadow: const [
          BoxShadow(
              blurRadius: 4.0, color: kColorShadow, offset: Offset(0.0, 2.0))
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
                      child: const Icon(Icons.broken_image,
                          color: kColorSecondaryText),
                    ),
                  ),
                ),
                // Nút Xóa (Thùng rác)
                Align(
                  alignment: const Alignment(0.9, -0.8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                        color: kColorOverlay, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: kColorError, size: 20.0),
                      onPressed: () => _removeSavedRecipe(id),
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
                  Text(title,
                      style: GoogleFonts.interTight(
                          color: kColorPrimaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 18.0)),
                  const SizedBox(height: 4.0),
                  Text(details,
                      style: GoogleFonts.inter(
                          color: kColorSecondaryText, fontSize: 12.0)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      // Icon Bookmark màu xanh
                      const Icon(Icons.bookmark,
                          color: kColorPrimary, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text("Đã lưu",
                          style: GoogleFonts.inter(
                              color: kColorPrimary,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold)),
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

  // Thanh điều hướng dưới cùng
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
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
            // Đã ở trang này (hoặc chuyển về MyRecipe nếu trang này là tab phụ)
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyRecipeScreen()));
            break;
          case 2:
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddRecipeScreen()));
            break;
          case 3:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const PantryScreen()));
            break;
          case 4:
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()));
            break;
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Recipe'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), label: 'Plus'),
        BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Pantry'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ],
    );
  }
}
