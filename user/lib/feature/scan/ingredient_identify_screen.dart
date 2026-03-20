import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/scan_service.dart';
import '../scan/pantry_screen.dart'; // Để navigate về pantry sau khi lưu

class IngredientIdentifyScreen extends StatefulWidget {
  final File imageFile;
  final List<Map<String, dynamic>> initialIngredients;

  const IngredientIdentifyScreen({
    super.key,
    required this.imageFile,
    required this.initialIngredients,
  });

  @override
  State<IngredientIdentifyScreen> createState() =>
      _IngredientIdentifyScreenState();
}

class _IngredientIdentifyScreenState extends State<IngredientIdentifyScreen> {
  late List<Map<String, dynamic>> _ingredients;
  bool _isSaving = false;

  // Theme Colors
  final Color kBgColor = const Color(0xFF151522);
  final Color kCardColor = const Color(0xFF222232);
  final Color kPrimaryColor = const Color(0xFF568C4C);

  @override
  void initState() {
    super.initState();
    // Clone dữ liệu để không ảnh hưởng biến gốc
    _ingredients = List.from(widget.initialIngredients);
  }

  // --- HÀM LƯU TẤT CẢ VÀO TỦ LẠNH ---
  Future<void> _saveAllToPantry() async {
    setState(() => _isSaving = true);

    // BƯỚC 1: Upload ảnh gốc lên Server để lấy đường dẫn (URL)
    String finalImageUrl = "";
    try {
      // Gọi API upload ảnh
      final uploadResult = await ScanService.uploadFoodImage(widget.imageFile);
      if (uploadResult['success'] == true) {
        finalImageUrl = uploadResult['filePath']; // Server trả về đường dẫn ảnh (vd: uploads/abc.jpg)
      }
    } catch (e) {
      print("⚠️ Lỗi upload ảnh gốc: $e");
      // Nếu lỗi upload thì finalImageUrl vẫn rỗng -> App sẽ tự fallback sang ảnh Google như cũ
    }

    // BƯỚC 2: Lưu từng món kèm theo link ảnh vừa có
    int successCount = 0;
    for (var item in _ingredients) {
      // Chuẩn hóa dữ liệu trước khi gửi
      final Map<String, dynamic> dataToSend = {
        "name": item['name'],
        "quantity": double.tryParse(item['quantity'].toString()) ?? 1.0,
        "unit": item['unit'] ?? "cái",
        "weight": double.tryParse(item['weight'].toString()) ?? 0.0,
        "expiryDate": item['expiryDate'], 
        "storage": item['storage'] ?? "Ngăn mát",
        "category": item['category'] ?? "Khác",
        
        // 🔥 QUAN TRỌNG: Gán link ảnh gốc vào đây
        // Nếu item đã có ảnh (từ tìm kiếm) thì ưu tiên dùng, nếu không thì dùng ảnh chụp gốc
        "image_url": (item['image_url'] != null && item['image_url'].isNotEmpty) 
            ? item['image_url'] 
            : finalImageUrl 
      };

      final result = await ScanService.addToPantry(dataToSend);
      if (result['success'] == true) {
        successCount++;
      }
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Đã lưu $successCount/${_ingredients.length} món vào tủ!"),
      backgroundColor: kPrimaryColor,
    ));

    // Quay về và báo thành công
    Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const PantryScreen()),
    (route) => false,
    );
  }

  // --- HỘP THOẠI CHỈNH SỬA MÓN ---
  void _showEditDialog(int index) {
    final item = _ingredients[index];

    final nameCtrl = TextEditingController(text: item['name']);
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());
    final unitCtrl = TextEditingController(
        text: item['unit'] ?? "cái"); // 🔥 Cho phép sửa Unit
    final weightCtrl = TextEditingController(text: item['weight'].toString());

    // Parse Date
    DateTime selectedDate = DateTime.tryParse(item['expiryDate'] ?? "") ??
        DateTime.now().add(const Duration(days: 7));
    final dateCtrl = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));

    String currentStorage = item['storage'] ?? "Ngăn mát";
    bool isFrozen =
        currentStorage.contains("đông") || currentStorage.contains("FREEZER");

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
              Future<void> pickDate() async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setStateDialog(() {
                    selectedDate = picked;
                    dateCtrl.text =
                        DateFormat('dd/MM/yyyy').format(selectedDate);
                  });
                }
              }

              return AlertDialog(
                backgroundColor: kCardColor,
                title: const Text("Chỉnh sửa thông tin",
                    style: TextStyle(color: Colors.white)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tên món
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: "Tên món",
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Số lượng
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: "SL",
                                  labelStyle: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Đơn vị (Unit) - 🔥 QUAN TRỌNG ĐỂ ĐỒNG BỘ
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: unitCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: "Đơn vị (củ/g)",
                                  labelStyle: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Trọng lượng (Optional)
                      TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: "Trọng lượng quy đổi (g)",
                            labelStyle: TextStyle(color: Colors.grey),
                            suffixText: "g"),
                      ),
                      const SizedBox(height: 10),
                      // Storage Switch
                      SwitchListTile(
                        title: Text(isFrozen ? "❄️ Ngăn đông" : "🌱 Ngăn mát",
                            style: const TextStyle(color: Colors.white)),
                        value: isFrozen,
                        activeColor: Colors.blue,
                        onChanged: (val) =>
                            setStateDialog(() => isFrozen = val),
                      ),
                      // Date Picker
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        style: const TextStyle(color: Colors.orange),
                        decoration: const InputDecoration(
                            labelText: "Hết hạn ngày",
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.calendar_today,
                                color: Colors.orange, size: 18)),
                        onTap: pickDate,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy",
                          style: TextStyle(color: Colors.white54))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor),
                    onPressed: () {
                      setState(() {
                        _ingredients[index] = {
                          ..._ingredients[index],
                          "name": nameCtrl.text,
                          "quantity": qtyCtrl.text,
                          "unit": unitCtrl.text, // 🔥 Lưu unit user đã sửa
                          "weight": weightCtrl.text,
                          "storage": isFrozen ? "Ngăn đông" : "Ngăn mát",
                          "expiryDate": selectedDate
                              .toIso8601String(), // Lưu format chuẩn ISO để Backend đọc được
                        };
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("Xong",
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              );
            }));
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Text("Kết quả Quét",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // ẢNH CHỤP GỐC
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                    image: FileImage(widget.imageFile), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ]),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final item = _ingredients[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Icon category
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            const Icon(Icons.fastfood, color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            // HIỂN THỊ ĐÚNG FORMAT: 1 củ / 200g
                            Text("${item['quantity']} ${item['unit']}",
                                style: const TextStyle(color: Colors.grey)),
                            Text(
                                "HSD: ${DateFormat('dd/MM').format(DateTime.parse(item['expiryDate']))}",
                                style: TextStyle(
                                    color: item['storage'] == 'Ngăn đông'
                                        ? Colors.blueAccent
                                        : Colors.greenAccent,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _showEditDialog(index),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _removeIngredient(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: kCardColor,
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAllToPantry,
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Lưu Vào Tủ Lạnh",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
