import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
// 👇 Import Service
import '../services/recipe_service.dart';

// --- ĐỒNG BỘ MÀU SẮC ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorAppBar = Color(0xFFFFFFFF);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorSecondary = Color(0xFF45B7D1);
const Color kColorError = Color(0xFFFF5963);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);

const Color kChartFat = Color(0xFFFBC02D);
const Color kChartCarbs = Color(0xFF0288D1);
const Color kColorProtein = Color(0xFFE64A19);

// Options
const List<String> kTimeOptions = [
  'Dưới 15 phút',
  '15-30 phút',
  '30-60 phút',
  'Trên 1 giờ'
];
final List<String> kServingsOptions =
    List.generate(12, (index) => '${index + 1} người');

class UpdateRecipeScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const UpdateRecipeScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<UpdateRecipeScreen> createState() => _UpdateRecipeScreenState();
}

class IngredientController {
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;

  IngredientController()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        unit = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}

class _UpdateRecipeScreenState extends State<UpdateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _descriptionController; // Dùng cho Steps (Cách làm)
  late TextEditingController _videoUrlController;

  File? _newImageFile;
  File? _newVideoFile; // ✅ MỚI: Biến lưu file video mới chọn

  String? _selectedTime;
  String? _selectedServings;
  
  // ✅ MỚI: Thêm độ khó
  String? _selectedDifficulty;
  final List<String> _difficultyOptions = ['Dễ', 'Trung bình', 'Khó'];

  final List<IngredientController> _ingredientRows = [];

  // Dữ liệu dinh dưỡng
  Map<String, dynamic>? _nutritionData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 1. Fill thông tin cơ bản
    _nameController = TextEditingController(
        text: widget.recipe['name'] ?? widget.recipe['title']);

    // Fill mô tả ngắn
    _shortDescController =
        TextEditingController(text: widget.recipe['description'] ?? '');

    // Fill Video URL cũ
    String currentVideo = "";
    if (widget.recipe['video'] != null) {
        if (widget.recipe['video'] is String) {
            currentVideo = widget.recipe['video'];
        } else if (widget.recipe['video'] is Map) {
            currentVideo = widget.recipe['video']['url'] ?? "";
        }
    }
    // Nếu là link http (Youtube/Tiktok...) thì điền vào ô text, nếu là path file upload thì để trống
    if (currentVideo.startsWith('http') && !currentVideo.contains('/uploads/')) {
         _videoUrlController = TextEditingController(text: currentVideo);
    } else {
         _videoUrlController = TextEditingController();
    }

    // 2. Fill Steps
    String stepsText = "";
    if (widget.recipe['steps'] != null && widget.recipe['steps'] is List) {
      List<dynamic> steps = widget.recipe['steps'];
      // Backend trả về mảng object { description: "..." }
      stepsText = steps.map((s) => s['description'] ?? s.toString()).join("\n");
    }
    _descriptionController = TextEditingController(text: stepsText);

    // 3. Fill Thời gian
    String? oldTime;
    if (widget.recipe['cookTimeMinutes'] != null) {
        oldTime = _convertMinutesToOption(widget.recipe['cookTimeMinutes']);
    } else {
        oldTime = widget.recipe['time'];
    }

    if (kTimeOptions.contains(oldTime)) {
      _selectedTime = oldTime;
    } else {
      _selectedTime = kTimeOptions[1]; // Default 15-30p
    }

    // 4. Fill Khẩu phần
    int servingsNum = widget.recipe['servings'] ?? 2;
    _selectedServings = "$servingsNum người";
    
    // 5. Fill Độ khó
    _selectedDifficulty = widget.recipe['difficulty'] ?? 'Trung bình';

    // 6. Fill Nguyên liệu
    if (widget.recipe['ingredients'] != null) {
      List<dynamic> oldIngredients = widget.recipe['ingredients'];
      for (var item in oldIngredients) {
        _addIngredientRow(
            name: item['name'] ?? '',
            quantity: item['quantity']?.toString() ?? '',
            unit: item['unit'] ?? '');
      }
    } else {
      _addIngredientRow();
    }

    // 7. Fill Dinh dưỡng
    _nutritionData = widget.recipe['nutritionAnalysis'];
  }

  String _convertMinutesToOption(int minutes) {
    if (minutes < 15) return 'Dưới 15 phút';
    if (minutes <= 30) return '15-30 phút';
    if (minutes <= 60) return '30-60 phút';
    return 'Trên 1 giờ';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    for (var row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _newImageFile = File(image.path));
  }

  // ✅ LOGIC CHỌN VIDEO MỚI
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _newVideoFile = File(video.path);
        _videoUrlController.clear(); // Xóa link youtube nếu chọn file
      });
    }
  }

  void _removeVideo() {
    setState(() => _newVideoFile = null);
  }

  void _addIngredientRow(
      {String name = '', String quantity = '', String unit = ''}) {
    setState(() {
      final newController = IngredientController();
      newController.name.text = name;
      newController.quantity.text = quantity;
      newController.unit.text = unit;
      _ingredientRows.add(newController);
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientRows[index].dispose();
      _ingredientRows.removeAt(index);
    });
  }

  Future<void> _analyzeNutrition() async {
    List<Map<String, dynamic>> ingredientsToSend = [];
    for (var row in _ingredientRows) {
      if (row.name.text.isNotEmpty) {
        ingredientsToSend.add({
          "name": row.name.text,
          "quantity": double.tryParse(row.quantity.text) ?? 1,
          "unit": row.unit.text.isEmpty ? "gram" : row.unit.text,
        });
      }
    }

    if (ingredientsToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Vui lòng nhập nguyên liệu để phân tích")));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await RecipeService.analyzeIngredients(ingredientsToSend);
      if (result['success'] == true) {
        setState(() => _nutritionData = result['data']);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã cập nhật dinh dưỡng mới!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi phân tích: ${result['message']}")));
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e")));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Xử lý Video Logic:
        // - Nếu có File mới -> Upload lấy path mới.
        // - Nếu có Link URL mới -> Dùng link đó.
        // - Nếu cả 2 trống -> Giữ nguyên video cũ.
        
        String? finalVideoPath;
        
        if (_newVideoFile != null) {
            // Case 1: Upload video mới
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tải video lên...")));
            finalVideoPath = await RecipeService.uploadVideo(_newVideoFile!);
            if (finalVideoPath == null) throw "Lỗi upload video";
        } else if (_videoUrlController.text.isNotEmpty) {
            // Case 2: Link Youtube mới
            finalVideoPath = _videoUrlController.text;
        } else {
            // Case 3: Giữ nguyên video cũ
            // Cẩn thận: Backend trả về object hoặc string, cần parse lại path chuẩn
            if (widget.recipe['video'] is String) {
                finalVideoPath = widget.recipe['video'];
            } else if (widget.recipe['video'] is Map) {
                finalVideoPath = widget.recipe['video']['url'];
            }
        }

        // 2. Map Ingredients
        final ingredients = _ingredientRows.map((row) {
          return {
            'name': row.name.text,
            'quantity': double.tryParse(row.quantity.text) ?? 0,
            'unit': row.unit.text
          };
        }).toList();

        // 3. Map Steps
        List<Map<String, String>> steps = _descriptionController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => {"description": s.trim()})
            .toList();

        // 4. Map Time
        int cookTime = 30;
        if (_selectedTime == 'Dưới 15 phút') cookTime = 15;
        else if (_selectedTime == '30-60 phút') cookTime = 60;
        else if (_selectedTime == 'Trên 1 giờ') cookTime = 90;

        // 5. Map Servings
        int servings = int.tryParse(_selectedServings!.split(' ')[0]) ?? 2;

        final updateData = {
          "name": _nameController.text,
          "description": _shortDescController.text.isNotEmpty 
              ? _shortDescController.text 
              : _nameController.text, 
          "servings": servings,
          "cookTimeMinutes": cookTime,
          "difficulty": _selectedDifficulty ?? 'Trung bình', // Gửi độ khó
          "ingredients": ingredients,
          "steps": steps,
          "video": finalVideoPath, // Path video đã xử lý
          "nutritionAnalysis": _nutritionData,
          // Lưu ý: Tags nếu không sửa thì Backend giữ nguyên (nhờ logic của Mongoose $set)
          // Hoặc bạn có thể thêm UI sửa tags nếu cần thiết.
        };

        final result = await RecipeService.updateRecipe(
            widget.recipe['_id'], updateData, _newImageFile);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cập nhật thành công!")));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: ${result['message']}")));
        }
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: $e")));
      } finally {
         if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: AppBar(
          backgroundColor: kColorAppBar,
          elevation: 0,
          leading: const BackButton(color: kColorPrimaryText),
          title: Text(
            'Chỉnh sửa công thức',
            style: GoogleFonts.interTight(
                color: kColorPrimaryText, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                        controller: _nameController,
                        label: 'Tên món ăn',
                        hint: 'Nhập tên món'),
                    const SizedBox(height: 12),

                    _buildTextField(
                        controller: _shortDescController,
                        label: 'Mô tả ngắn',
                        hint: 'Giới thiệu đôi nét về món ăn này...',
                        minLines: 2,
                        maxLines: 3,
                        textInputAction: TextInputAction.done),

                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Khẩu phần',
                            value: _selectedServings,
                            items: kServingsOptions,
                            onChanged: (v) =>
                                setState(() => _selectedServings = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Thời gian',
                            value: _selectedTime,
                            items: kTimeOptions,
                            onChanged: (v) => setState(() => _selectedTime = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // ✅ Dropdown Độ khó
                    _buildDropdownField(
                        label: 'Độ khó',
                        value: _selectedDifficulty,
                        items: _difficultyOptions,
                        onChanged: (v) => setState(() => _selectedDifficulty = v),
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle('Nguyên liệu'),
                    _buildIngredientList(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: kColorPrimary),
                      label: Text('Thêm dòng',
                          style: GoogleFonts.inter(
                              color: kColorPrimary,
                              fontWeight: FontWeight.bold)),
                      onPressed: () => _addIngredientRow(),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Các bước làm',
                      hint: 'Mỗi bước 1 dòng...',
                      minLines: 5,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Video hướng dẫn'),
                    // ✅ Widget chọn video
                    _buildVideoSelectionSection(),

                    const SizedBox(height: 20),
                    _buildNutritionSection(),

                    const SizedBox(height: 30),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.5),
                child: const Center(
                    child: CircularProgressIndicator(color: kColorPrimary)),
              )
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildVideoSelectionSection() {
    return Column(
      children: [
        _buildVideoPicker(), // Nút chọn file
        const SizedBox(height: 12),
        Center(
            child: Text("- HOẶC -",
                style:
                    TextStyle(color: kColorSecondaryText, fontSize: 12))),
        const SizedBox(height: 12),
        TextFormField(
          controller: _videoUrlController,
          keyboardType: TextInputType.url,
          // Nếu nhập link thì xoá file đã chọn để tránh conflict
          onChanged: (value) {
            if (value.isNotEmpty && _newVideoFile != null) {
              setState(() => _newVideoFile = null);
            }
          },
          decoration: InputDecoration(
            labelText: 'Link YouTube/TikTok',
            hintText: 'https://youtube.com/...',
            filled: true,
            fillColor: kColorCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabled: _newVideoFile == null, // Disable nhập link nếu đã chọn file
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kColorBorder)),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return InkWell(
      onTap: _pickVideo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kColorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kColorBorder, width: 1),
          // Nếu có video mới thì viền xanh
          boxShadow: _newVideoFile != null
              ? [
                  BoxShadow(
                      color: kColorPrimary.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _newVideoFile != null
                    ? kColorPrimary.withOpacity(0.1)
                    : kColorBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _newVideoFile != null
                    ? Icons.videocam
                    : Icons.video_library_outlined,
                color: _newVideoFile != null
                    ? kColorPrimary
                    : kColorSecondaryText,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _newVideoFile != null
                        ? 'Đã chọn video mới'
                        : 'Thay đổi video (Tải lên từ máy)',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: kColorPrimaryText,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _newVideoFile != null
                        ? _newVideoFile!.path.split('/').last
                        : 'Chạm để chọn (Giữ nguyên nếu không chọn)',
                    style: GoogleFonts.inter(
                        color: kColorSecondaryText, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_newVideoFile != null)
              IconButton(
                icon: const Icon(Icons.close, color: kColorError),
                onPressed: _removeVideo,
              )
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    ImageProvider? bgImage;
    if (_newImageFile != null) {
      bgImage = FileImage(_newImageFile!);
    } else {
      String? oldUrl = widget.recipe['image'];
      if (oldUrl != null && oldUrl.isNotEmpty) {
        if (!oldUrl.startsWith('http')) {
             if (oldUrl.startsWith('/')) oldUrl = oldUrl.substring(1);
             oldUrl = "${RecipeService.domain}/$oldUrl";
        }
        bgImage = NetworkImage(oldUrl);
      }
    }

    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200.0,
        decoration: BoxDecoration(
          color: kColorCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: kColorBorder, width: 2.0),
          image: bgImage != null
              ? DecorationImage(image: bgImage, fit: BoxFit.cover)
              : null,
        ),
        child: bgImage == null
            ? const Center(
                child: Icon(Icons.add_photo_alternate_outlined,
                    size: 48, color: kColorSecondaryText))
            : null,
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _ingredientRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = _ingredientRows[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 5,
                child: _buildTextField(
                    controller: row.name, label: 'Tên', hint: '')),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: _buildTextField(
                    controller: row.quantity,
                    label: 'SL',
                    hint: '',
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: _buildTextField(
                    controller: row.unit, label: 'Đơn vị', hint: '')),
            if (_ingredientRows.length > 1)
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: kColorError),
                onPressed: () => _removeIngredientRow(index),
              )
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    int? maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: kColorCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kColorBorder)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Nhập $label' : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: kColorCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kColorBorder)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: GoogleFonts.inter(
              color: kColorSecondaryText, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNutritionSection() {
    int servings = int.tryParse(_selectedServings?.split(' ')[0] ?? "1") ?? 1;
    if (servings < 1) servings = 1;

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _analyzeNutrition,
          icon: const Icon(Icons.analytics_outlined, color: kColorSecondary),
          label: const Text('Phân tích lại dinh dưỡng (AI)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: kColorSecondary),
          ),
        ),
        if (_nutritionData != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kColorBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kết quả phân tích',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: kColorPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Đang chia cho $servings người',
                          style: const TextStyle(
                              fontSize: 12,
                              color: kColorPrimary,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: 150, child: _buildPieChart()),
                const SizedBox(height: 16),
                _buildPieChartLegend(),
                const Divider(height: 30),

                _buildHeaderRow(),
                const SizedBox(height: 8),

                _buildNutritionRow(
                    'Calories', _nutritionData!['calories'], 'kcal', servings),
                _buildNutritionRow(
                    'Protein', _nutritionData!['protein'], 'g', servings),
                _buildNutritionRow(
                    'Carbs', _nutritionData!['carbs'], 'g', servings),
                _buildNutritionRow(
                    'Fat', _nutritionData!['fat'], 'g', servings),

                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Chi tiết khác (Đường, Muối...)',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: kColorPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    children: [
                      _buildNutritionRow('Đường',
                          _nutritionData!['sugars'] ?? 0, 'g', servings),
                      _buildNutritionRow('Muối',
                          _nutritionData!['sodium'] ?? 0, 'mg', servings),
                    ],
                  ),
                ),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(flex: 4, child: Text('')),
          Expanded(
              flex: 3,
              child: Text('Tổng (Nồi)',
                  style: TextStyle(color: kColorSecondaryText, fontSize: 12),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text('1 Người',
                  style: TextStyle(
                      color: kColorPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
      String label, dynamic totalValue, String unit, int servings) {
    double total = (totalValue as num?)?.toDouble() ?? 0;
    double perServing = total / servings;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: const TextStyle(color: kColorSecondaryText)),
          ),
          Expanded(
            flex: 3,
            child: Text('${total.toStringAsFixed(0)} $unit',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text('${perServing.toStringAsFixed(1)} $unit',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kColorPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    double protein = (_nutritionData!['protein'] as num?)?.toDouble() ?? 0;
    double carbs = (_nutritionData!['carbs'] as num?)?.toDouble() ?? 0;
    double fat = (_nutritionData!['fat'] as num?)?.toDouble() ?? 0;
    double total = protein + carbs + fat;
    if (total == 0) total = 1;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
              value: protein, color: kColorProtein, title: '', radius: 50),
          PieChartSectionData(
              value: carbs, color: kChartCarbs, title: '', radius: 50),
          PieChartSectionData(
              value: fat, color: kChartFat, title: '', radius: 50),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _legendItem(kColorProtein, "Protein"),
      _legendItem(kChartCarbs, "Carbs"),
      _legendItem(kChartFat, "Fat"),
    ]);
  }

  Widget _legendItem(Color color, String text) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12))
    ]);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                side: const BorderSide(color: kColorError)),
            child: const Text('Hủy', style: TextStyle(color: kColorError)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _updateRecipe,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50), backgroundColor: kColorPrimary),
            child: const Text('Lưu thay đổi',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}