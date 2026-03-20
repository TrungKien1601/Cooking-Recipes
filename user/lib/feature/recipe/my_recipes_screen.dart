import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/recipe_service.dart';
import '../recipe/blog_screen.dart';
import 'add_recipe_screen.dart';
import 'update_recipe_screen.dart'; 
import '../home/homepage_screen.dart';

class MyRecipeScreen extends StatefulWidget {
  const MyRecipeScreen({super.key});

  @override
  State<MyRecipeScreen> createState() => _MyRecipeScreenState();
}

class _MyRecipeScreenState extends State<MyRecipeScreen> {
  bool _isLoading = true;
  List<dynamic> _myRecipes = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchMyRecipes();
  }

  // --- Lấy ID user -> Gọi API lọc bài của user đó ---
  Future<void> _fetchMyRecipes() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      String? userId = prefs.getString('userId');
      if (userId == null) {
        String? userData = prefs.getString('user_data');
        if (userData != null) {
          final data = jsonDecode(userData);
          userId = data['_id'] ?? data['id'];
        }
      }

      _currentUserId = userId;

      if (userId == null) {
        print("⚠️ Không tìm thấy User ID.");
        setState(() => _isLoading = false);
        return;
      }

      // Gọi API lấy bài của chính user này
      final result = await RecipeService.getAllRecipes(
        authorId: userId,
        excludeAi: true,
        limit: 100, // Lấy nhiều chút
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _myRecipes = result['data'] ?? [];
          } else {
            _myRecipes = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi My Recipe: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Thay vì pop, ta chuyển hướng hẳn về HomePage để tránh lỗi stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Công thức của tôi',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: Color(0xFF568C4C)),
            onPressed: () async {
              // Chuyển sang trang thêm và đợi kết quả
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddRecipeScreen()),
              );
              // Nếu đăng thành công thì load lại danh sách
              if (result == true) {
                _fetchMyRecipes();
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF568C4C)))
          : _myRecipes.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  // Giao diện khi chưa có bài nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Bạn chưa đăng công thức nào",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddRecipeScreen()),
              );
              if (result == true) _fetchMyRecipes();
            },
            icon: const Icon(Icons.add),
            label: const Text("Tạo công thức ngay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF568C4C),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _myRecipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(dynamic recipe) {
    String title = recipe['name'] ?? "Chưa đặt tên";
    String id = recipe['_id'];

    // Xử lý ảnh: Nếu là path upload (không phải http) thì nối thêm domain
    String imageUrl = recipe['image'] ?? "";
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      if (!imageUrl.startsWith('/')) {
        imageUrl = "${RecipeService.domain}/$imageUrl";
      } else {
        imageUrl = "${RecipeService.domain}$imageUrl";
      }
    }

    String time = recipe['cookTimeMinutes'] != null
        ? "${recipe['cookTimeMinutes']} phút"
        : "30 phút";

    // Trạng thái bài viết
    String status = recipe['status'] ?? "Chờ duyệt";

    return GestureDetector(
      onTap: () {
        // Chuyển sang xem chi tiết
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BlogScreen(recipeData: {
                      
                      ...recipe, 
                  
                      'name': title,
                      'image': imageUrl, // URL đã nối domain
                      'time': time,      // Thời gian đã format
                      'isOwner': true,   // Đánh dấu là chủ sở hữu
                      
                      // Đảm bảo fallback
                      'description': recipe['description'] ?? "",
                      'ingredients': recipe['ingredients'] ?? [],
                      'instructions': recipe['steps'] ?? recipe['instructions'] ?? [],
                    }))).then((_) => _fetchMyRecipes());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ảnh món ăn
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            // Thông tin
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge trạng thái
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'Đã duyệt'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'Đã duyệt'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        // Menu (Sửa / Xóa)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz,
                              size: 20, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              _confirmDelete(id);
                            } else if (value == 'edit') {
                              // LOGIC SỬA BÀI VIẾT
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Truyền toàn bộ object recipe vào màn hình sửa
                                  builder: (context) =>
                                      UpdateRecipeScreen(recipe: recipe),
                                ),
                              );

                              // Nếu sửa thành công, load lại danh sách
                              if (result == true) {
                                _fetchMyRecipes();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Đã cập nhật bài viết")),
                                );
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Sửa')
                              ]),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Xóa', style: TextStyle(color: Colors.red))
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF15161E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(time,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM XÓA BÀI VIẾT ---
  Future<void> _confirmDelete(String recipeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa công thức này không?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await RecipeService.deleteRecipe(recipeId);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Đã xóa thành công")));
          _fetchMyRecipes(); // Load lại danh sách
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: ${result['message']}")));
        }
      }
    }
  }
}