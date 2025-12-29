import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/scan_service.dart';
import '../scan/qr_scanner_screen.dart';
import '../scan/ingredient_scanner_screen.dart';
import '../recipe/blog_screen.dart'; 
import '../auth/login_screen.dart';
import '../home/homepage_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  static const Color kPrimaryColor = Color(0xFF568C4C);
  static const Color kCardColor = Color(0xFF222232); // Màu nền tối cho Dialog/Sheet

  List<dynamic> _pantryItems = [];
  bool _isLoading = true;
  bool _isSuggesting = false;

  // Variables cho lịch sử
  List<dynamic> _historyList = [];
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadPantryData();
  }

  Future<void> _loadPantryData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final result = await ScanService.getPantry();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _pantryItems = result['data'];
      } else {
        _handleError(result['message']);
      }
    });
  }

  void _handleError(String? message) {
    final msg = (message ?? "Lỗi tải dữ liệu").toLowerCase();
    if (msg.contains("hết hạn") || msg.contains("401")) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
    } else {
      _showSnackBar(message ?? "Đã có lỗi xảy ra");
    }
  }

  Future<void> _deleteItem(String id, int index) async {
    final deletedItem = _pantryItems[index];
    setState(() => _pantryItems.removeAt(index));
    final result = await ScanService.deleteItem(id);
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _pantryItems.insert(index, deletedItem));
      _showSnackBar("Lỗi xóa món ăn", isError: true);
    } else {
      _showSnackBar("Đã xóa");
    }
  }

  // --- SỬA MÓN (ĐÃ FIX LỖI CHỌN LỊCH) ---
  void _showEditPantryItem(int index) {
    final item = _pantryItems[index];

    final TextEditingController nameCtrl =
        TextEditingController(text: item['name']);
    final TextEditingController qtyCtrl =
        TextEditingController(text: item['quantity'].toString());
    final TextEditingController weightCtrl =
        TextEditingController(text: item['weight'].toString());

    // Xử lý ngày tháng ban đầu
    DateTime selectedDate = PantryHelper.parseDate(item['expiryDate']);

    // Controller riêng cho ngày tháng (Để hiển thị text đẹp)
    final TextEditingController dateCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(selectedDate)
    );

    // Check storage từ backend trả về
    String currentStorage = item['storage']?.toString().toUpperCase() ?? "";
    bool isFrozen =
        currentStorage.contains("ĐÔNG") || currentStorage.contains("FREEZER");
    
    // Thêm biến loading cho dialog
    bool _isSavingDialog = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        
        // Logic đổi ngăn đông/mát
        void toggleFreezer(bool value) {
          setStateDialog(() {
            isFrozen = value;
          });
        }
        
        // Hàm chọn lịch
        Future<void> pickDateDialog() async {
          final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime(2100),
              builder: (context, child) {
                  return Theme(
                      data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: kPrimaryColor, // Màu xanh chủ đạo
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                          ),
                      ),
                      child: child!,
                  );
              },
          );
          if (picked != null) {
            setStateDialog(() {
              selectedDate = picked;
              // Cập nhật text hiển thị sau khi chọn
              dateCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDate);
            });
          }
        }

        return AlertDialog(
          backgroundColor: kCardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Chỉnh sửa thông tin",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Tên món",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.greenAccent),
                        decoration: const InputDecoration(
                            labelText: "Số lượng",
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child:
                            Text("x", style: TextStyle(color: Colors.white))),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            labelText: "Nặng/Dung tích",
                            labelStyle: const TextStyle(color: Colors.grey),
                            suffixText: item['unit'] ?? "",
                            border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(isFrozen ? "❄️ Ngăn đông" : "🌱 Ngăn mát",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  value: isFrozen,
                  activeColor: Colors.blueAccent,
                  onChanged: toggleFreezer,
                ),
                const SizedBox(height: 16),
                
                
                TextField(
                  controller: dateCtrl, // Hiển thị ngày tháng
                  readOnly: true,       // Chặn bàn phím, chỉ bắt click
                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: "Hạn sử dụng",
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.orange),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white54), 
                  ),
                  onTap: pickDateDialog, // Bấm vào gọi hàm chọn lịch
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Hủy", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: _isSavingDialog ? null : () async {
                setStateDialog(() => _isSavingDialog = true); // Kích hoạt loading
                
                final updateData = {
                  "name": nameCtrl.text,
                  // Dùng double.tryParse an toàn
                  "quantity": double.tryParse(qtyCtrl.text) ?? 1.0, 
                  "weight": double.tryParse(weightCtrl.text) ?? 0.0,
                  "expiryDate": selectedDate.toIso8601String(),
                  "storage": isFrozen ? "Ngăn đông" : "Ngăn mát"
                };

                final result =
                    await ScanService.updateItem(item['_id'], updateData);

                if (!mounted) return;
                
                // Dù thành công hay thất bại, đóng dialog
                Navigator.pop(context); 
                
                if (result['success'] == true) {
                  // Tải lại toàn bộ dữ liệu để đảm bảo cập nhật
                  _loadPantryData(); 
                  _showSnackBar("Cập nhật thành công!");
                } else {
                  _showSnackBar(result['message'], isError: true);
                }
              },
              // Hiển thị loading (UX)
              child: _isSavingDialog
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Lưu thay đổi", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  // --- Show History ---
  void _showHistorySheet() {
    _selectedIds.clear();
    _isSelectionMode = false;
    _historyList.clear();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF151522),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => StatefulBuilder(
            builder: (context, setModalState) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, controller) => Column(children: [
                      const SizedBox(height: 10),
                      Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _isSelectionMode
                                    ? TextButton(
                                        onPressed: () {
                                          setModalState(() {
                                            _isSelectionMode = false;
                                            _selectedIds.clear();
                                          });
                                        },
                                        child: const Text("Hủy",
                                            style:
                                                TextStyle(color: Colors.grey)))
                                    : Text("Lịch sử Gợi ý",
                                        style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                _isSelectionMode
                                    ? TextButton.icon(
                                        onPressed: _selectedIds.isEmpty
                                            ? null
                                            : () async {
                                                  final idsToDelete =
                                                      _selectedIds.toList();
                                                  final result = await ScanService
                                                      .deleteHistoryItems(
                                                          idsToDelete);
                                                  if (result['success'] == true) {
                                                    setModalState(() {
                                                      _historyList.removeWhere(
                                                          (item) => idsToDelete
                                                              .contains(
                                                                  item['_id']));
                                                      _selectedIds.clear();
                                                      _isSelectionMode = false;
                                                    });
                                                    if (mounted)
                                                      _showSnackBar(
                                                          "Đã xóa ${idsToDelete.length} mục");
                                                  } else {
                                                    if (mounted)
                                                      _showSnackBar(
                                                          result['message'],
                                                          isError: true);
                                                  }
                                                },
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        label: Text(
                                            "Xóa (${_selectedIds.length})",
                                            style: const TextStyle(
                                                color: Colors.redAccent)))
                                    : IconButton(
                                        icon: const Icon(Icons.checklist,
                                            color: Colors.white),
                                        tooltip: "Chọn để xóa",
                                        onPressed: () => setModalState(
                                            () => _isSelectionMode = true),
                                      )
                              ])),
                      Expanded(
                          child: FutureBuilder<Map<String, dynamic>>(
                              future: _historyList.isEmpty
                                  ? ScanService.getRecipeHistory()
                                  : Future.value(
                                      {'success': true, 'data': _historyList}),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    _historyList.isEmpty) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!['success'] == false) {
                                  if (_historyList.isNotEmpty)
                                    return _buildHistoryList(
                                        setModalState, controller);
                                  return const Center(
                                      child: Text("Lỗi tải lịch sử",
                                          style:
                                              TextStyle(color: Colors.grey)));
                                }
                                if (_historyList.isEmpty)
                                  _historyList = snapshot.data!['data'] as List;
                                if (_historyList.isEmpty)
                                  return const Center(
                                      child: Text("Chưa có lịch sử nào",
                                          style:
                                              TextStyle(color: Colors.grey)));
                                return _buildHistoryList(
                                    setModalState, controller);
                              })),
                    ]))));
  }

  Widget _buildHistoryList(
      StateSetter setModalState, ScrollController controller) {
    return ListView.builder(
        controller: controller,
        itemCount: _historyList.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, index) {
          final session = _historyList[index];
          final String id = session['_id'];
          final DateTime date =
              DateTime.tryParse(session['createdAt'] ?? "") ?? DateTime.now();
          final bool isSelected = _selectedIds.contains(id);

          return GestureDetector(
            onLongPress: () => setModalState(() {
              _isSelectionMode = true;
              _selectedIds.add(id);
            }),
            onTap: _isSelectionMode
                ? () => setModalState(() =>
                    isSelected ? _selectedIds.remove(id) : _selectedIds.add(id))
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _isSelectionMode && isSelected
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF222232),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _isSelectionMode && isSelected
                          ? Colors.redAccent
                          : Colors.white10)),
              child: Row(children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Checkbox(
                      value: isSelected,
                      activeColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.grey),
                      onChanged: (val) => setModalState(() => val == true
                          ? _selectedIds.add(id)
                          : _selectedIds.remove(id)),
                    ),
                  ),
                Expanded(
                  child: ExpansionTile(
                      key: PageStorageKey(id),
                      enabled: !_isSelectionMode,
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.orange,
                      title: Text(DateFormat('dd/MM/yyyy - HH:mm').format(date),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${(session['recipes'] as List).length} món được gợi ý",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      children: (session['recipes'] as List)
                          .map((recipe) => _buildRecipeTile(recipe))
                          .toList()),
                ),
              ]),
            ),
          );
        });
  }

  // --- GỢI Ý MÓN ---
  Future<void> _showRecipeSuggestions() async {
    if (_pantryItems.isEmpty) {
      _showSnackBar("Tủ lạnh trống trơn!");
      return;
    }
    setState(() => _isSuggesting = true);
    final result = await ScanService.suggestChefRecipes(null);
    setState(() => _isSuggesting = false);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSuggestionSheet(result['data']);
    } else {
      _showSnackBar(result['message'] ?? "AI chưa nghĩ ra món nào...",
          isError: true);
    }
  }

  void _showSuggestionSheet(List<dynamic> recipes) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF151522),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) => ListView.builder(
                controller: controller,
                itemCount: recipes.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (ctx, index) =>
                    _buildRecipeTile(recipes[index], isCard: true))));
  }

  Widget _buildRecipeTile(dynamic recipe, {bool isCard = false}) {
    final tile = ListTile(
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<String>(
              future: ImageSearchHelper.findImage(recipe['name'] ?? "food"),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(strokeWidth: 2));
                return Image.network(snapshot.data!,
                    width: isCard ? 60 : 50,
                    height: isCard ? 60 : 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.restaurant, color: Colors.orange));
              })),
      title: Text(recipe['name'] ?? "Món ngon",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: isCard
          ? Text(
              "${recipe['calories'] ?? 0} kcal • ${recipe['cooking_time'] ?? '30p'}",
              style: const TextStyle(color: Colors.grey))
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: () {
        // --- CHUẨN BỊ DỮ LIỆU ---
        final Map<String, dynamic> detailData = {
          'name': recipe['name'],
          'image': Uri.encodeFull(recipe['image_url'] ?? recipe['image'] ?? '').toString(),
          'description': recipe['description'] ??
              "Món ${recipe['name']} thơm ngon, đầy đủ dinh dưỡng.",
          'difficulty': recipe['difficulty'],
          'chef_tips': recipe['chef_tips'],
          'time': recipe['cooking_time'],
          'calories': recipe['calories'],
          'ingredients': (recipe['all_ingredients'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              (recipe['ingredients_used'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ["Đang cập nhật..."],
          'instructions':
              (recipe['steps'] as List?)?.map((e) => e.toString()).toList() ??
                  (recipe['instructions'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  ["Đang cập nhật hướng dẫn..."],
          'macros': recipe['macros'] ?? {'protein': 0, 'carbs': 0, 'fat': 0},
        };

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BlogScreen(recipeData: detailData)));
      },
    );
    return isCard
        ? Card(
            color: const Color(0xFF222232),
            margin: const EdgeInsets.only(bottom: 12),
            child: tile)
        : tile;
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Thêm nguyên liệu mới",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildMenuItem(Icons.qr_code_scanner, "Quét mã vạch", Colors.blue,
                  () async {
                Navigator.pop(ctx);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                if (mounted) _loadPantryData();
              }),
              _buildMenuItem(
                  Icons.camera_enhance, "Quét nguyên liệu (AI)", Colors.orange,
                  () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IngredientScannerScreen()));
                if (result == true && mounted) _loadPantryData();
              }),
            ])),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return ListTile(
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color)),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : kPrimaryColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Tủ lạnh của tôi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false)),
        actions: [
          IconButton(
              icon: const Icon(Icons.history, color: Colors.black),
              onPressed: _showHistorySheet),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadPantryData)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPantryData,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF5F7FA),
              child: ElevatedButton.icon(
                onPressed: (_isSuggesting || _isLoading)
                    ? null
                    : _showRecipeSuggestions,
                icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                label:
                    Text(_isSuggesting ? "Đang suy nghĩ..." : "Gợi ý món ăn"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor))
                  : _pantryItems.isEmpty
                      ? const Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Icon(Icons.kitchen,
                                  size: 100, color: Colors.grey),
                              SizedBox(height: 20),
                              Text("Tủ lạnh trống trơn!",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))
                            ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pantryItems.length,
                          itemBuilder: (context, index) {
                            final item = _pantryItems[index];
                            return PantryItemTile(
                              key: Key(item['_id'] ?? "$index"),
                              item: item,
                              baseUrl: ScanService.baseUrl,
                              onDelete: () => _deleteItem(item['_id'], index),
                              onEdit: () => _showEditPantryItem(index),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm đồ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ============================================================================
// --- SUB-WIDGET: PANTRY ITEM TILE ---
// ============================================================================
class PantryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String baseUrl;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PantryItemTile({
    super.key,
    required this.item,
    required this.baseUrl,
    required this.onDelete,
    required this.onEdit,
  });

  String _fmt(dynamic num) {
    if (num == null) return "0";
    double val = double.tryParse(num.toString()) ?? 0;
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime expDate = PantryHelper.parseDate(item['expiryDate']);
    final Color cardColor = PantryHelper.getExpirationColor(expDate);
    final Color statusColor = PantryHelper.getTextColor(expDate);

    // Lấy dữ liệu
    double weight = double.tryParse(item['weight'].toString()) ?? 0;
    double quantity = double.tryParse(item['quantity'].toString()) ?? 0;
    String unit = item['unit'] ?? "cái";

    // --- LOGIC HIỂN THỊ CÂN NẶNG ---
    String weightUnit = "gram"; 
    if (['kg', 'g', 'gram', 'ml', 'l', 'lít'].contains(unit.toLowerCase())) {
      weightUnit = unit;
    }

    String weightText = "";
    if (weight > 0) {
      if (quantity > 1) {
        // Nếu nhiều món: "500 gram/phần"
        weightText = "${_fmt(weight)} $weightUnit/phần"; 
      } else {
        // Nếu 1 món: "500 gram"
        weightText = "${_fmt(weight)} $weightUnit";
      }
    }

    // --- LOGIC HIỂN THỊ STORAGE ---
    String storageRaw = item['storage']?.toString().toUpperCase() ?? "FRIDGE";
    bool isFrozen = storageRaw.contains("ĐÔNG") || storageRaw.contains("FREEZER");

    String storageLabel = "Tủ bếp";
    Color storageColor = Colors.brown;
    IconData storageIcon = Icons.inventory_2;

    if (isFrozen) {
      storageLabel = "Ngăn đông";
      storageColor = Colors.blue;
      storageIcon = Icons.ac_unit;
    } else if (storageRaw.contains("MÁT") || storageRaw.contains("FRIDGE")) {
      storageLabel = "Ngăn mát";
      storageColor = Colors.green;
      storageIcon = Icons.kitchen;
    }

    String? serverImage = item['image_url']?.toString();
    bool hasServerImage = serverImage != null && serverImage.isNotEmpty;
    bool isExpired = expDate.difference(DateTime.now()).inDays < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
              color: isExpired ? Colors.red : statusColor.withOpacity(0.3),
              width: isExpired ? 1.5 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CỘT TRÁI: ẢNH ---
            Stack(
              children: [
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200]),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasServerImage
                            ? _buildServerImage(serverImage!)
                            : _buildGoogleImage(item['name'] ?? "Food"))),
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: storageColor, shape: BoxShape.circle),
                        child: Icon(storageIcon, color: Colors.white, size: 12))),
              ],
            ),
            const SizedBox(width: 16),

            // --- CỘT GIỮA: THÔNG TIN ---
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? "Không tên",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),

                      // DÒNG 1: SỐ LƯỢNG
                      Row(children: [
                        const Icon(Icons.format_list_numbered,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                            // Nếu unit là gram thì ghi là "Định lượng", còn lại ghi "SL"
                            "${weightUnit == unit ? 'SL' : 'SL'}: ${_fmt(quantity)}",
                            style: TextStyle(color: Colors.grey[800], fontSize: 13))
                      ]),

                      // DÒNG 2: CÂN NẶNG (HIỆN NẾU > 0)
                      if (weight > 0) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.scale, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          // Luôn hiện chuỗi weightText đã xử lý ở trên
                          Text("Nặng: $weightText",
                              style: TextStyle(
                                  color: Colors.grey[800], fontSize: 13))
                        ]),
                      ],

                      // DÒNG 3: HẠN SỬ DỤNG
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red.withOpacity(0.1)
                                  : statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.access_time,
                                size: 14,
                                color: isExpired ? Colors.red : statusColor),
                            const SizedBox(width: 4),
                            Text(PantryHelper.getStatusText(expDate),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.red : statusColor))
                          ]))
                    ])),

            // --- CỘT PHẢI: NÚT ---
            Column(
              children: [
                IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero),
                const SizedBox(height: 15),
                IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero)
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServerImage(String path) {
    String finalUrl = PantryHelper.getValidImageUrl(path, baseUrl);
    return Image.network(finalUrl,
        fit: BoxFit.cover,
        headers: const {"ngrok-skip-browser-warning": "true"},
        errorBuilder: (c, e, s) =>
            const Icon(Icons.fastfood, color: Colors.grey));
  }

  Widget _buildGoogleImage(String query) {
    return FutureBuilder<String>(
      future: ImageSearchHelper.findImage(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2));
        return Image.network(snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.restaurant, color: Colors.grey));
      },
    );
  }
}

// ... (Giữ nguyên ImageSearchHelper) ...
class ImageSearchHelper {
  static const String _apiKey = "AIzaSyAksWw3AwgHO7SaQw5bQZZDBkGQh_4G-88";
  static const String _cxId = "81194332729ef486f";
  static final Map<String, String> _cache = {};

  static Future<String> findImage(String query) async {
    if (_cache.containsKey(query)) return _cache[query]!;
    final String searchUrl =
        "https://www.googleapis.com/customsearch/v1?q=$query food dish&cx=$_cxId&key=$_apiKey&searchType=image&num=1&imgSize=medium";
    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          String url = data['items'][0]['link'];
          _cache[query] = url;
          return url;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    String fallback =
        "https://image.pollinations.ai/prompt/${Uri.encodeComponent(query)}%20food";
    _cache[query] = fallback;
    return fallback;
  }
}

class PantryHelper {
  static String getValidImageUrl(String? path, String baseUrl) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    String cleanPath = path.replaceAll(r'\\', '/');
    if (cleanPath.startsWith("/")) cleanPath = cleanPath.substring(1);

    // LOGIC FIX QUAN TRỌNG: Cắt bỏ đuôi "/api" và xử lý trailing slash
    String domainUrl = baseUrl;
    if (domainUrl.endsWith("/"))
      domainUrl = domainUrl.substring(0, domainUrl.length - 1);
    if (domainUrl.endsWith("/api"))
      domainUrl = domainUrl.substring(0, domainUrl.length - 4);

    return "$domainUrl/$cleanPath";
  }

  static DateTime parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now().add(const Duration(days: 365));
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  static Color getExpirationColor(DateTime date) =>
      date.difference(DateTime.now()).inDays < 0
          ? Colors.red.shade100
          : Colors.white;
  static Color getTextColor(DateTime date) =>
      date.difference(DateTime.now()).inDays < 0
          ? Colors.red.shade700
          : Colors.green.shade700;
  static String getStatusText(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    return diff < 0
        ? "Đã hết hạn"
        : (diff == 0 ? "Hết hạn hôm nay" : "Còn $diff ngày");
  }
}