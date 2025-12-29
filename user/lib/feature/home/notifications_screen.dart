import 'package:cooking_recipes_books/feature/recipe/blog_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
// import '../recipe/blog_screen.dart'; // Đảm bảo import đúng đường dẫn

// --- CONSTANTS ---
const Color kPrimaryBackground = Color(0xFFF1F4F8);
const Color kCardBackground = Color(0xFFE3ECE1);
const Color kListBackground = Color(0xFFF1F4F8);
const Color kPrimaryText = Color(0xFF14181B);
const Color kSecondaryText = Color(0xFF57636C);
const Color kBorderColor = Color(0xFFE0E3E7);
const Color kIndicatorColor = Color(0xFF4B39EF);
const Color kIconBorder = Color(0xFF4B39EF);
const Color kIconBackground = Color(0x4C4B39EF);
const Color kErrorColor = Color(0xFFFF5963);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> _allNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    
    final result = await RecipeService.getNotifications();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          _allNotifications = result['data'];
        }
      });
    }
  }

  // --- LOGIC BẤM VÀO THÔNG BÁO (CHỈ XEM, KHÔNG XÓA) ---
  Future<void> _onNotificationTap(Map<String, dynamic> notification) async {
    // 1. Đánh dấu đã đọc trên UI ngay lập tức
    if (notification['isRead'] == false) {
      setState(() {
        notification['isRead'] = true;
      });
      // Gọi API đánh dấu đã đọc ngầm
      RecipeService.markNotificationAsRead(notification['_id']);
    }

    String? targetId = notification['targetId'];
    if (targetId == null) return;

    // Kiểm tra bài viết
    final result = await RecipeService.getRecipeDetail(targetId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      // Chuyển trang
      // Navigator.push(context, MaterialPageRoute(builder: (_) => BlogScreen(recipeId: targetId)));
      print("🚀 Navigate to Recipe: ${result['data']['name']}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bài viết không tồn tại."), backgroundColor: kErrorColor),
      );
    }
  }

  // --- 🔥 [MỚI] LOGIC XÓA THÔNG BÁO ---
  Future<void> _onDeleteNotification(String id) async {
    // Hiển thị hộp thoại xác nhận trước khi xóa
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa thông báo?"),
        content: const Text("Bạn có chắc muốn xóa thông báo này vĩnh viễn không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Tiến hành xóa
    // 1. Gọi API Xóa
    final result = await RecipeService.deleteNotification(id); // Bạn cần thêm hàm này vào Service

    if (!mounted) return;

    if (result['success'] == true) {
      // 2. Xóa khỏi danh sách local để cập nhật UI
      setState(() {
        _allNotifications.removeWhere((item) => item['_id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa thông báo")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi khi xóa thông báo"), backgroundColor: kErrorColor),
      );
    }
  }
  
  String _formatTime(String? dateString) {
    if (dateString == null) return "";
    final date = DateTime.parse(dateString).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${date.day}/${date.month}";
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Lọc danh sách chưa đọc
    final unreadNotifications = _allNotifications.where((n) => n['isRead'] == false).toList();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryBackground,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.85,
                      minHeight: 400.0,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kCardBackground,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [
                          BoxShadow(blurRadius: 12.0, color: Color(0x1A000000), offset: Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16.0),
                          _buildHeader(),
                          Expanded(
                            child: Column(
                              children: [
                                _buildTabBar(),
                                Expanded(
                                  child: _isLoading 
                                    ? const Center(child: CircularProgressIndicator(color: kIndicatorColor))
                                    : TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildNotificationList(unreadNotifications, isNewTab: true),
                                        _buildNotificationList(_allNotifications, isNewTab: false),
                                      ],
                                    ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Nút tắt popup
              Positioned(
                top: 16, right: 16,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.close_rounded, color: kPrimaryText, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Thông báo', style: GoogleFonts.plusJakartaSans(color: kPrimaryText, fontSize: 22.0, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.refresh, color: kSecondaryText),
            onPressed: _fetchNotifications,
          )
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: kPrimaryText,
        unselectedLabelColor: kSecondaryText,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 16.0, fontWeight: FontWeight.w600),
        indicatorColor: kIndicatorColor,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Mới'), Tab(text: 'Tất cả')],
      ),
    );
  }

  Widget _buildNotificationList(List<dynamic> notifications, {required bool isNewTab}) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: kSecondaryText.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text("Không có thông báo nào", style: GoogleFonts.plusJakartaSans(color: kSecondaryText)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      child: Container(
        color: kListBackground,
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: kBorderColor, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final bool isRead = item['isRead'] ?? false;
              
              return InkWell(
                onTap: () => _onNotificationTap(item),
                child: NotificationItemCard(
                  title: item['title'] ?? 'Thông báo',
                  subtitle: item['message'] ?? '',
                  time: _formatTime(item['createdAt']),
                  isHighlighted: !isRead, 
                  // Truyền hàm xóa vào đây
                  onDelete: () => _onDeleteNotification(item['_id']),
                  iconWidget: isRead ? _buildCheckIcon() : _buildRadioIcon(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCheckIcon() {
    return Container(
      width: 24.0, height: 24.0,
      decoration: BoxDecoration(color: kIconBackground, shape: BoxShape.circle, border: Border.all(color: kIconBorder, width: 2.0)),
      child: const Icon(Icons.check_rounded, color: kIconBorder, size: 16.0),
    );
  }

  Widget _buildRadioIcon() {
    return Container(
      width: 24.0, height: 24.0,
      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: kIndicatorColor, width: 2.0)),
      child: const Icon(Icons.circle, color: kIndicatorColor, size: 12.0),
    );
  }
}

// --- CẬP NHẬT UI ITEM CARD ĐỂ CÓ NÚT XÓA ---
class NotificationItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isHighlighted;
  final Widget iconWidget;
  final VoidCallback onDelete; // Callback xóa

  const NotificationItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isHighlighted = false,
    required this.iconWidget,
    required this.onDelete, // Yêu cầu truyền hàm xóa
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isHighlighted ? Colors.white : const Color(0xFFF1F4F8), 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột nội dung chính
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Tiêu đề
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            color: kPrimaryText,
                            fontSize: 16.0,
                            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600, 
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icon trạng thái (Đã xem/Chưa xem) để cạnh tiêu đề hoặc để cuối dòng tùy bạn
                      // Ở code cũ bạn để iconWidget ở cuối Row lớn, tôi giữ nguyên logic đó bên dưới
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(color: kSecondaryText, fontSize: 14.0, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(color: kSecondaryText.withOpacity(0.7), fontSize: 12.0, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            // Cột bên phải: Icon trạng thái + Nút Xóa
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: iconWidget, // Icon tròn check/radio
                ),
                const SizedBox(height: 12),
                // NÚT XÓA THÊM VÀO ĐÂY
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Icon(
                      Icons.delete_outline_rounded, 
                      color: kSecondaryText, // Hoặc màu đỏ kErrorColor nếu muốn nổi bật
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}