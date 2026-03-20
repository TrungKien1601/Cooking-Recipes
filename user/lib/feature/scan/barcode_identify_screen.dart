import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/scan_service.dart';

class BarcodeResultScreen extends StatefulWidget {
  final String? scannedCode;

  const BarcodeResultScreen({super.key, this.scannedCode});

  @override
  State<BarcodeResultScreen> createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends State<BarcodeResultScreen> {
  // --- STATE ---
  bool _isLoading = true;
  bool _isAdding = false;
  Map<String, dynamic>? _productData;

  // --- FORM DATA ---
  final TextEditingController _quantityController =
      TextEditingController(text: "1");
  String _selectedUnit = "gói";
  String _selectedStorage = "Tủ bếp"; // Mặc định đồ đóng gói để tủ bếp
  DateTime? _expiryDate;

  // Danh sách đơn vị & Nơi lưu trữ
  final List<String> _unitOptions = [
    "gói",
    "hộp",
    "gram",
    "chai",
    "lon",
    "cái",
    "kg",
    "lít"
  ];
  final List<String> _storageOptions = ["Ngăn mát", "Ngăn đông", "Tủ bếp"];

  // --- COLORS ---
  final Color kBgColor = const Color(0xFF151522);
  final Color kCardColor = const Color(0xFF222232);
  final Color kPrimaryColor = const Color(0xFF568C4C);
  final Color kTextWhite = Colors.white;
  final Color kTextGrey = const Color(0xFF9E9EA5);
  final Color kColorFat = const Color(0xFFFACC15);
  final Color kColorCarb = const Color(0xFF3B82F6);
  final Color kColorProtein = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fetchBarcodeInfo();
    // Mặc định đồ đóng gói hạn dài hơn (30 ngày)
    _expiryDate = DateTime.now().add(const Duration(days: 30));
  }

  void _fetchBarcodeInfo() async {
    if (widget.scannedCode == null) return;

    final result = await ScanService.scanBarcode(widget.scannedCode!);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true || (result['found'] == true)) {
        // Backend có thể trả về structure khác nhau tùy cache hay mới scan
        _productData = result['data'] ?? result;

        // Auto-select Unit nếu API trả về
        String? apiUnit = _productData!['unit'];
        if (apiUnit != null && apiUnit.isNotEmpty) {
          // Map sơ bộ về tiếng Việt nếu cần, hoặc add vào list
          if (!_unitOptions.contains(apiUnit)) {
            _unitOptions.add(apiUnit);
          }
          _selectedUnit = apiUnit;
        }

        // Auto-detect storage: Nếu là kem/thịt thì mặc định tủ lạnh (Logic phụ thôi)
        String cat = (_productData!['category'] ?? "").toLowerCase();
        if (cat.contains('đông') || cat.contains('kem'))
          _selectedStorage = "Ngăn đông";
        else if (cat.contains('sữa') || cat.contains('thịt'))
          _selectedStorage = "Ngăn mát";
      } else {
        _showErrorDialog(result['message'] ?? "Không tìm thấy sản phẩm này");
      }
    });
  }

  // --- HÀM LƯU VÀO TỦ LẠNH (QUAN TRỌNG) ---
  void _addToPantry() async {
    if (_isAdding) return;
    if (_productData == null) return;

    setState(() => _isAdding = true);

    // 1. Lấy thông tin dinh dưỡng (Thường là per 100g/100ml)
    var nutrients = _productData!['nutrients'] ?? {};
    double baseCal =
        double.tryParse(nutrients['calories']?.toString() ?? "0") ?? 0;

    // 2. Lấy số lượng user nhập
    double quantityInput =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;

    // 3. Tính toán Calo & Weight gửi đi
    double totalCal = 0;
    double weightToSend = 0;

    // Logic tính toán dựa trên đơn vị
    if (['gram', 'g', 'ml'].contains(_selectedUnit.toLowerCase())) {
      // Nếu nhập 500g -> weight = 500, calo = (base / 100) * 500
      weightToSend = quantityInput;
      totalCal = (baseCal / 100) * quantityInput;
    } else if (['kg', 'l', 'lít', 'liter']
        .contains(_selectedUnit.toLowerCase())) {
      // Nếu nhập 1kg -> weight = 1000g
      weightToSend = quantityInput * 1000;
      totalCal = (baseCal / 100) * weightToSend;
    } else {
      totalCal =
          baseCal * quantityInput; // Tạm tính: 1 gói = 100g chuẩn của API
    }

    // 4. Chuẩn bị Data
    final newItem = {
      "name": _productData?['name'] ?? "Sản phẩm mã vạch",
      "category": _productData?['category'] ?? "Đồ đóng gói",

      // Gửi cả quantity và weight (nếu là gram)
      "quantity": quantityInput,
      "weight": weightToSend > 0
          ? weightToSend
          : 0, // Backend ưu tiên weight nếu unit là gram/kg

      "unit": _selectedUnit,
      "storage": _selectedStorage, // Quan trọng: Gửi nơi lưu trữ
      "addMethod": "BARCODE", // Quan trọng: Để biết nguồn

      "image_url": _productData?['image_url'] ?? "",
      "calories": totalCal,
      "expiryDate": _expiryDate?.toIso8601String(),

      // Nếu Backend tìm thấy trong cache, nó có thể có _id (MasterID giả lập)
      "masterIngredientId":
          _productData?['_id'] // Gửi kèm nếu có để backend link
    };

    try {
      final result = await ScanService.addToPantry(newItem);

      if (!mounted) return;
      setState(() => _isAdding = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Đã thêm ${_productData!['name']} vào $_selectedStorage!"),
              backgroundColor: kPrimaryColor),
        );
        Navigator.pop(context, true); // Pop về và reload list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Lỗi: ${result['message']}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isAdding = false);
      print(e);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
                primary: kPrimaryColor,
                onPrimary: Colors.white,
                surface: kCardColor,
                onSurface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text("Thông báo", style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: kTextGrey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Quay lại"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgColor,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_productData == null) return const Scaffold();

    // Hiển thị dinh dưỡng (Per 100g) để user tham khảo
    final nutrients = _productData!['nutrients'] ?? {};
    double baseCal =
        double.tryParse(nutrients['calories']?.toString() ?? "0") ?? 0;
    double baseFat = double.tryParse(nutrients['fat']?.toString() ?? "0") ?? 0;
    double baseCarb =
        double.tryParse(nutrients['carbs']?.toString() ?? "0") ?? 0;
    double baseProtein =
        double.tryParse(nutrients['protein']?.toString() ?? "0") ?? 0;

    String imgUrl = _productData!['image_url'] ?? "";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kBgColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: kBgColor,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: Text("Kết quả quét",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- ẢNH SẢN PHẨM ---
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (imgUrl.isNotEmpty)
                              ? Image.network(imgUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: kTextGrey))
                              : const Icon(Icons.qr_code_2,
                                  size: 60, color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _productData!['name'] ?? "Tên sản phẩm",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: kTextWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          border: Border.all(color: kPrimaryColor),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_productData!['category'] ?? "Khác",
                          style: GoogleFonts.inter(
                              color: kPrimaryColor, fontSize: 12)),
                    ),

                    const SizedBox(height: 24),

                    // MACROS (Per 100g) - Hiển thị để tham khảo
                    Text("Giá trị dinh dưỡng (trên 100g/ml)",
                        style: TextStyle(
                            color: kTextGrey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroCircle(baseCal),
                        _buildMacroColumn(
                            "PROTEIN",
                            "${baseProtein.toStringAsFixed(1)}g",
                            kColorProtein),
                        _buildMacroColumn("CARBS",
                            "${baseCarb.toStringAsFixed(1)}g", kColorCarb),
                        _buildMacroColumn(
                            "FAT", "${baseFat.toStringAsFixed(1)}g", kColorFat),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Mô tả
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Mô tả",
                            style: GoogleFonts.inter(
                                color: kTextWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                          _productData!['description'] ?? "Không có mô tả.",
                          style: TextStyle(
                              color: kTextGrey,
                              fontStyle: FontStyle.italic,
                              height: 1.4)),
                    ),
                    const SizedBox(
                        height: 100), // Padding bottom cho BottomSheet
                  ],
                ),
              ),
            ),
          ],
        ),

        // --- BOTTOM SHEET (FORM NHẬP LIỆU) ---
        bottomSheet: Container(
          color: kCardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Số lượng - Đơn vị - Nơi lưu trữ
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInputColumn(
                        "Số lượng",
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: kTextWhite, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 5)),
                        )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildInputColumn(
                        "Đơn vị",
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            dropdownColor: kCardColor,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: kTextGrey),
                            style: TextStyle(color: kTextWhite),
                            items: _unitOptions
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedUnit = val!),
                          ),
                        )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildInputColumn(
                        "Lưu tại",
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStorage,
                            dropdownColor: kCardColor,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: kTextGrey),
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            items: _storageOptions
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedStorage = val!),
                          ),
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Hàng 2: Hạn sử dụng
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                      color: kBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Hạn sử dụng:", style: TextStyle(color: kTextGrey)),
                      Text(
                        _expiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                            : "Chọn ngày",
                        style: TextStyle(
                            color: kPrimaryColor, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.calendar_today, color: kTextGrey, size: 16)
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _addToPantry,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Thêm vào tủ lạnh",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER HELPERS ---

  Widget _buildInputColumn(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: kTextGrey, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: kBgColor, borderRadius: BorderRadius.circular(8)),
          child: Center(child: child),
        )
      ],
    );
  }

  Widget _buildMacroCircle(double cal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
                backgroundColor: Colors.grey.shade800)),
        Column(children: [
          Text(cal.toStringAsFixed(0),
              style: GoogleFonts.inter(
                  color: kTextWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text("Kcal",
              style: GoogleFonts.inter(color: kTextGrey, fontSize: 10)),
        ])
      ],
    );
  }

  Widget _buildMacroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.inter(
                color: kTextWhite, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: kTextGrey, fontSize: 10)),
      ],
    );
  }
}
