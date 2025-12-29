import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/scan_service.dart';

class IngredientIdentifyScreen extends StatefulWidget {
  final File imageFile;
  final List<dynamic> detectedIngredients;

  const IngredientIdentifyScreen(
      {super.key, required this.imageFile, required this.detectedIngredients});

  @override
  State<IngredientIdentifyScreen> createState() =>
      _IngredientIdentifyScreenState();
}

class _IngredientIdentifyScreenState extends State<IngredientIdentifyScreen> {
  List<dynamic> _ingredients = [];
  bool _isSaving = false;
  bool _isAddingMore = false;

  final Color kPrimaryColor = const Color(0xFF568C4C);
  final Color kBgColor = const Color(0xFF151522);
  final Color kCardColor = const Color(0xFF222232);

  final TextStyle kInputLabel =
      const TextStyle(color: Colors.grey, fontSize: 12);
  final TextStyle kInputValue = const TextStyle(
      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16);

  // Danh sách danh mục chuẩn
  final List<String> _categories = [
    "Thịt",
    "Hải sản",
    "Rau củ",
    "Trái cây",
    "Trứng/Sữa",
    "Gia vị/Đồ khô",
    "Đồ uống",
    "Khác"
  ];

  @override
  void initState() {
    super.initState();
    _initData(widget.detectedIngredients, sourceImage: widget.imageFile);
  }

  void _initData(List<dynamic> newItems, {File? sourceImage}) {
    final processedItems = newItems.map((item) {
      if (item['localImage'] == null) {
        item['localImage'] = sourceImage;
      }

      item['base_weight'] = double.tryParse(item['weight'].toString()) ?? 0.0;
      item['user_quantity'] = int.tryParse(item['quantity'].toString()) ?? 1;
      item['unit'] = item['unit'] ?? 'gram';

      // Xử lý category: Nếu không có hoặc không thuộc list chuẩn thì gán "Khác"
      String cat = item['category'] ?? "Khác";
      if (!_categories.contains(cat)) {
        cat = "Khác";
      }
      item['category'] = cat;

      String storage = item['storage']?.toString().toUpperCase() ?? "FRIDGE";
      item['isFrozen'] =
          (storage.contains("FREEZER") || storage.contains("ĐÔNG"));

      if (item['expiryDate'] == null) {
        item['expiryDate'] =
            DateTime.now().add(const Duration(days: 7)).toIso8601String();
      } else {
        // [FIX LỖI NGÀY AI] Đảm bảo ngày không lùi về quá khứ
        DateTime expiry = DateTime.tryParse(item['expiryDate']) ??
            DateTime.now().add(const Duration(days: 7));
        if (expiry
            .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          // Nếu AI trả ngày hôm qua hoặc cũ hơn, đặt lại thành 7 ngày từ hôm nay
          expiry = DateTime.now().add(const Duration(days: 7));
        }
        item['expiryDate'] = expiry.toIso8601String();
      }

      item['calories'] = double.tryParse(item['calories'].toString()) ?? 0;

      return item;
    }).toList();

    if (!mounted) return;
    setState(() {
      _ingredients.addAll(processedItems);
    });
  }

  Future<void> _pickAndScanMore() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text("Chụp ảnh mới",
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final XFile? photo =
                  await picker.pickImage(source: ImageSource.camera);
              if (photo != null) _processNewImage(File(photo.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text("Chọn từ thư viện",
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final XFile? photo =
                  await picker.pickImage(source: ImageSource.gallery);
              if (photo != null) _processNewImage(File(photo.path));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _processNewImage(File file) async {
    setState(() => _isAddingMore = true);
    try {
      final result = await ScanService.scanImage(file);

      if (result['success'] == true && result['data'] != null) {
        List<dynamic> newItems = [];
        if (result['data'] is List) {
          newItems = result['data'];
        } else {
          newItems = [result['data']];
        }

        _initData(newItems, sourceImage: file);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Đã thêm món mới!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Không nhận diện được món nào."),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Lỗi scan thêm: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isAddingMore = false);
    }
  }

  void _showEditDialog(int index) {
    final item = _ingredients[index];

    // 1. Controller cho các trường Text
    final TextEditingController nameCtrl =
        TextEditingController(text: item['name']);
    final TextEditingController qtyCtrl =
        TextEditingController(text: item['user_quantity'].toString());
    final TextEditingController weightCtrl =
        TextEditingController(text: item['base_weight'].toString());

    // 2. Xử lý ngày tháng ban đầu
    DateTime selectedDate;
    try {
      selectedDate = DateTime.parse(item['expiryDate']);
    } catch (e) {
      selectedDate = DateTime.now().add(const Duration(days: 7));
    }

    // 3. Controller riêng cho ngày tháng (Để hiển thị text đẹp)
    final TextEditingController dateCtrl = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));

    bool isFrozen = item['isFrozen'] ?? false;
    String currentUnit = item['unit'] ?? 'gram';

    // Biến lưu trạng thái người dùng đã chọn ngày thủ công chưa
    bool _hasManualDate = false;

    // Thêm biến loading cho dialog
    bool _isSavingDialog = false;

    // Lấy category hiện tại
    String currentCategory = item['category'] ?? "Khác";
    if (!_categories.contains(currentCategory)) {
      currentCategory = "Khác";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        // Logic đổi ngăn đông/mát
        void toggleFreezer(bool value) {
          setStateDialog(() {
            isFrozen = value;

            // [FIX GHI ĐÈ] Chỉ tự động đổi ngày nếu người dùng chưa chọn thủ công
            if (!_hasManualDate) {
              selectedDate =
                  DateTime.now().add(Duration(days: isFrozen ? 60 : 7));
              dateCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDate);
            }
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
                    primary: Color(0xFF568C4C), // Màu xanh chủ đạo
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
              // Báo hiệu đã chọn thủ công
              _hasManualDate = true;
              dateCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDate);
            });
          }
        }

        return AlertDialog(
          backgroundColor: kCardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Chi tiết nguyên liệu",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên món (Giữ nguyên)
                TextField(
                  controller: nameCtrl,
                  style: kInputValue,
                  decoration: InputDecoration(
                    labelText: "Tên",
                    labelStyle: kInputLabel,
                    fillColor: Colors.white10,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // [MỚI] THÊM DROPDOWN CHỌN DANH MỤC Ở ĐÂY
                DropdownButtonFormField<String>(
                  value: currentCategory,
                  decoration: InputDecoration(
                    labelText: "Phân loại",
                    labelStyle: kInputLabel,
                    fillColor: Colors.white10,
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                  dropdownColor: kCardColor, // Màu nền menu xổ xuống
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => currentCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Số lượng & Trọng lượng (Giữ nguyên)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: kInputValue.copyWith(color: Colors.greenAccent),
                        decoration: InputDecoration(
                          labelText: "Số lượng",
                          labelStyle: kInputLabel,
                          border: const OutlineInputBorder(),
                          fillColor: Colors.white10,
                          filled: true,
                        ),
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("x", style: TextStyle(color: Colors.white))),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        style: kInputValue,
                        decoration: InputDecoration(
                          labelText: "Nặng/Dung tích",
                          labelStyle: kInputLabel,
                          suffixText: currentUnit,
                          border: const OutlineInputBorder(),
                          fillColor: Colors.white10,
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Switch Ngăn đông (Logic đã sửa)
                SwitchListTile(
                  title: const Text("Bảo quản ngăn đông?",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: isFrozen,
                  activeColor: Colors.blueAccent,
                  onChanged: toggleFreezer,
                ),
                const SizedBox(height: 16),

                // Chọn Hạn sử dụng (Đã FIX lỗi không phản ứng)
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  style: kInputValue,
                  decoration: InputDecoration(
                    labelText: "Hạn sử dụng",
                    labelStyle: kInputLabel,
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Colors.orange),
                    border: const OutlineInputBorder(),
                    fillColor: Colors.white10,
                    filled: true,
                    suffixIcon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white54),
                  ),
                  onTap: pickDateDialog,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: _isSavingDialog
                  ? null
                  : () {
                      setStateDialog(() => _isSavingDialog = true);

                      // Cập nhật dữ liệu vào _ingredients (màn hình chính)
                      setState(() {
                        _ingredients[index]['name'] = nameCtrl.text;
                        _ingredients[index]['category'] = currentCategory; // Cập nhật category
                        _ingredients[index]['user_quantity'] =
                            int.tryParse(qtyCtrl.text) ?? 1;
                        _ingredients[index]['base_weight'] = double.tryParse(
                                weightCtrl.text.replaceAll(',', '.')) ??
                            0;
                        _ingredients[index]['expiryDate'] =
                            selectedDate.toIso8601String();
                        _ingredients[index]['isFrozen'] = isFrozen;
                      });

                      // Tắt loading và đóng dialog
                      Navigator.pop(context);
                    },
              // Hiển thị loading
              child: _isSavingDialog
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _saveAllToPantry() async {
    if (_ingredients.isEmpty) return;

    setState(() => _isSaving = true);
    int successCount = 0;

    Map<String, String> uploadedImageCache = {};

    for (var item in _ingredients) {
      double weightPerItem = double.parse(item['base_weight'].toString());
      int quantity = int.parse(item['user_quantity'].toString());
      bool isFrozen = item['isFrozen'] ?? false;
      String storageEnum = isFrozen ? "Ngăn đông" : "Ngăn mát";

      String finalImageUrl = item['image_url'] ?? "";
      File? localImage = item['localImage'];

      if (localImage != null) {
        String localPath = localImage.path;
        if (uploadedImageCache.containsKey(localPath)) {
          finalImageUrl = uploadedImageCache[localPath]!;
        } else {
          try {
            final uploadResult = await ScanService.uploadFoodImage(localImage);
            if (uploadResult['success'] == true) {
              finalImageUrl = uploadResult['filePath'];
              uploadedImageCache[localPath] = finalImageUrl;
            }
          } catch (e) {
            print("Lỗi upload ảnh: $e");
          }
        }
      }

      final dataToSend = {
        "name": item['name'],
        "category": item['category'] ?? "Khác",
        "quantity": quantity,
        "weight": weightPerItem,
        "unit": item['unit'] ?? "gram",
        "addMethod": "SCAN_IMAGE",
        "calories": item['calories'] ?? 0,
        "expiryDate": item['expiryDate'],
        "storage": storageEnum,
        "note": "AI Scan",
        "image_url": finalImageUrl
      };

      try {
        // Giả định hàm addToPantry nhận Map<String, dynamic>
        final res = await ScanService.addToPantry(dataToSend);
        if (res['success'] == true)
          successCount++;
        else {
          print("Lỗi server trả về: ${res['message']}");
        }
      } catch (e) {
        print("❌ Exception khi lưu: $e");
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã lưu $successCount món vào tủ lạnh!")));
      // Quay về PantryScreen (Pop 2 lần: Identify -> Scanner -> Pantry)
      Navigator.of(context).pop();
      Navigator.of(context).pop(true); // Pop và gửi true để Pantry reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi lưu, vui lòng thử lại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text("Kết quả Quét",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            onPressed: _isAddingMore ? null : _pickAndScanMore,
          )
        ],
      ),
      body: Column(
        children: [
          if (_isAddingMore)
            LinearProgressIndicator(
                backgroundColor: kBgColor, color: kPrimaryColor),
          Expanded(
            child: _ingredients.isEmpty
                ? const Center(
                    child: Text("Chưa có nguyên liệu nào",
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final item = _ingredients[index];
                      double baseWeight =
                          double.parse(item['base_weight'].toString());
                      int quantity =
                          int.parse(item['user_quantity'].toString());
                      bool isFrozen = item['isFrozen'] ?? false;
                      File? localImg = item['localImage'];
                      String unit = item['unit'] ?? 'gram';

                      return Card(
                        color: kCardColor,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: isFrozen
                                  ? Colors.blueAccent.withOpacity(0.5)
                                  : Colors.transparent),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: localImg != null
                                  ? Image.file(localImg, fit: BoxFit.cover)
                                  : Icon(
                                      isFrozen
                                          ? Icons.ac_unit
                                          : Icons.restaurant,
                                      color: Colors.grey),
                            ),
                          ),
                          title: Text(item['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "$quantity x ${baseWeight.toStringAsFixed(0)} $unit\n${isFrozen ? '❄️ Ngăn đông' : '🌱 Ngăn mát'}",
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueGrey),
                                onPressed: () => _showEditDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => setState(
                                    () => _ingredients.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: kCardColor,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_ingredients.isEmpty || _isSaving || _isAddingMore)
                    ? null
                    : _saveAllToPantry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Lưu Vào Tủ Lạnh",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}