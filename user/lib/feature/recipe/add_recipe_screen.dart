import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../services/recipe_service.dart';

// --- MÀU SẮC ---
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

const List<String> kTimeOptions = [
  'Dưới 15 phút',
  '15-30 phút',
  '30-60 phút',
  'Trên 1 giờ'
];

// --- DANH SÁCH ĐƠN VỊ CHUẨN ---
const List<String> kUnitOptions = [
  'g',
  'ml',
  'kg',
  'l',
  'tbsp',
  'tsp',
  'cup',
  'quả',
  'củ'
];

final List<String> kServingsOptions =
    List.generate(12, (index) => '${index + 1} người');

class AddRecipeScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRecipe;
  const AddRecipeScreen({super.key, this.existingRecipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

// --- CONTROLLER CHO NGUYÊN LIỆU ---
class IngredientController {
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController weight;
  final TextEditingController unit;
  bool isVerified;

  IngredientController()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        weight = TextEditingController(),
        unit = TextEditingController(),
        isVerified = false;

  void dispose() {
    name.dispose();
    quantity.dispose();
    weight.dispose();
    unit.dispose();
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _stepsController;
  late TextEditingController _videoUrlController;

  File? _selectedImage;
  File? _selectedVideo;

  // Data Tags
  List<dynamic> _apiMealTimeTags = [];
  List<dynamic> _apiDietTags = [];
  List<dynamic> _apiRegionTags = [];
  List<dynamic> _apiDishTypeTags = [];
  List<dynamic> _apiDifficultyTags = [];

  bool _isTagsLoading = true;

  final List<String> _selectedTags = [];

  String? _selectedTime;
  String? _selectedServings = "2 người";
  String? _selectedDifficulty = "Trung bình";

  final List<IngredientController> _ingredientRows = [];

  Map<String, dynamic>? _nutritionData;
  bool _isLoading = false;
  bool _isNutritionAnalyzed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortDescController = TextEditingController();
    _stepsController = TextEditingController();
    _videoUrlController = TextEditingController();

    if (widget.existingRecipe != null) {
      _nameController.text = widget.existingRecipe!['name'] ?? '';
      _shortDescController.text = widget.existingRecipe!['description'] ?? '';
    }

    _addIngredientRow();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    final result = await RecipeService.getCreateOptions();
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _apiMealTimeTags = result['data']['mealTimeTags'] ?? [];
          _apiDietTags = result['data']['dietTags'] ?? [];
          _apiRegionTags = result['data']['regionTags'] ?? [];
          _apiDishTypeTags = result['data']['dishtypeTags'] ?? [];
          _apiDifficultyTags = result['data']['difficultyTags'] ?? [];

          _isTagsLoading = false;
        });
      } else {
        setState(() => _isTagsLoading = false);
        _showSnackBar("Không tải được danh sách thẻ: ${result['message']}",
            isError: true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _stepsController.dispose();
    _videoUrlController.dispose();
    for (var row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _videoUrlController.clear();
      });
    }
  }

  void _removeVideo() {
    setState(() => _selectedVideo = null);
  }

  void _addIngredientRow() {
    setState(() {
      final controller = IngredientController();
      controller.name.addListener(_resetNutritionStatus);
      controller.quantity.addListener(_resetNutritionStatus);
      controller.weight.addListener(_resetNutritionStatus);
      controller.unit.addListener(_resetNutritionStatus);

      _ingredientRows.add(controller);
      _isNutritionAnalyzed = false;
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientRows[index].dispose();
      _ingredientRows.removeAt(index);
      _isNutritionAnalyzed = false;
    });
  }

  void _resetNutritionStatus() {
    if (_isNutritionAnalyzed) {
      setState(() {
        _isNutritionAnalyzed = false;
        _nutritionData = null;
      });
    }
  }

  Future<void> _analyzeNutrition() async {
    // --- BƯỚC CHẶN 1: KIỂM TRA TỪNG DÒNG NGUYÊN LIỆU ---
    for (var row in _ingredientRows) {
      if (row.name.text.isNotEmpty && !row.isVerified) {
        _showSnackBar("Vui lòng chọn nguyên liệu hợp lệ từ danh sách gợi ý!", isError: true);
        return;
      }
    }

    List<Map<String, dynamic>> ingredientsToSend = [];
    for (var row in _ingredientRows) {
      if (row.name.text.isNotEmpty) {
        double w = double.tryParse(row.weight.text.replaceAll(',', '.')) ?? 0;
        double q = double.tryParse(row.quantity.text.replaceAll(',', '.')) ?? 0;

        ingredientsToSend.add({
          "name": row.name.text,
          "quantity": q,
          "weight": w,
          "unit": row.unit.text.isEmpty ? "g" : row.unit.text,
        });
      }
    }

    if (ingredientsToSend.isEmpty) {
      _showSnackBar("Vui lòng nhập ít nhất 1 nguyên liệu", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await RecipeService.analyzeIngredients(ingredientsToSend);
      if (result['success'] == true) {
        setState(() {
          _nutritionData = result['data'];
          _isNutritionAnalyzed = true;
        });
        _showSnackBar("Đã phân tích xong!", isError: false);
      } else {
        _showSnackBar("Lỗi phân tích: ${result['message']}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối AI: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _findTagId(List<dynamic> sourceList, String nameToFind) {
    try {
      final tagObj = sourceList.firstWhere((t) => t['name'] == nameToFind);
      return tagObj['_id'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Vui lòng kiểm tra lại các ô nhập liệu", isError: true);
      return;
    }

    // --- BƯỚC CHẶN 2: KIỂM TRA LÚC ĐĂNG BÀI ---
    for (var row in _ingredientRows) {
      if (row.name.text.isNotEmpty && !row.isVerified) {
        _showSnackBar("Vui lòng chọn nguyên liệu hợp lệ từ danh sách gợi ý!", isError: true);
        return;
      }
    }

    if (_selectedImage == null) {
      _showSnackBar("Vui lòng chọn ảnh món ăn", isError: true);
      return;
    }
    if (!_isNutritionAnalyzed || _nutritionData == null) {
      _showSnackBar("Vui lòng nhấn 'Phân tích Dinh dưỡng' trước khi đăng!",
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalVideoPath;
      if (_selectedVideo != null) {
        _showSnackBar("Đang tải công thức lên...", isError: false);
        finalVideoPath = await RecipeService.uploadVideo(_selectedVideo!);
        if (finalVideoPath == null) throw "Lỗi tải video lên server";
      } else if (_videoUrlController.text.isNotEmpty) {
        finalVideoPath = _videoUrlController.text;
      }

      List<String> mealTimeTagsToSend = [];
      List<String> dietTagsToSend = [];
      List<String> regionTagsToSend = [];
      List<String> dishtypeTagsToSend = [];

      final mealTimeNames =
          _apiMealTimeTags.map((e) => e['name'].toString()).toSet();
      final dietNames = _apiDietTags.map((e) => e['name'].toString()).toSet();
      final regionNames =
          _apiRegionTags.map((e) => e['name'].toString()).toSet();
      final dishtypeNames =
          _apiDishTypeTags.map((e) => e['name'].toString()).toSet();

      for (var tag in _selectedTags) {
        if (mealTimeNames.contains(tag)) {
          String? id = _findTagId(_apiMealTimeTags, tag);
          if (id != null) mealTimeTagsToSend.add(id);
        } else if (dietNames.contains(tag)) {
          String? id = _findTagId(_apiDietTags, tag);
          if (id != null) dietTagsToSend.add(id);
        } else if (regionNames.contains(tag)) {
          String? id = _findTagId(_apiRegionTags, tag);
          if (id != null) regionTagsToSend.add(id);
        } else if (dishtypeNames.contains(tag)) {
          String? id = _findTagId(_apiDishTypeTags, tag);
          if (id != null) dishtypeTagsToSend.add(id);
        }
      }

      List<Map<String, dynamic>> ingredients = _ingredientRows
          .map((row) => {
                "name": row.name.text,
                "quantity": double.tryParse(row.quantity.text) ?? 0,
                "weight": double.tryParse(row.weight.text) ?? 0,
                "unit": row.unit.text.isEmpty ? "g" : row.unit.text,
              })
          .toList();

      List<Map<String, String>> steps = _stepsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => {"description": s.trim()})
          .toList();

      int cookTime = 30;
      if (_selectedTime == 'Dưới 15 phút')
        cookTime = 15;
      else if (_selectedTime == '30-60 phút')
        cookTime = 60;
      else if (_selectedTime == 'Trên 1 giờ') cookTime = 90;

      int servings = int.tryParse(_selectedServings!.split(' ')[0]) ?? 2;

      final recipeData = {
        "name": _nameController.text,
        "description": _shortDescController.text.isNotEmpty
            ? _shortDescController.text
            : "Món ngon mỗi ngày",
        "servings": servings,
        "cookTimeMinutes": cookTime,
        "difficulty": _selectedDifficulty ?? "Trung bình",
        "video": finalVideoPath,
        "ingredients": ingredients,
        "steps": steps,
        "nutritionAnalysis": _nutritionData,
        "mealTimeTags": mealTimeTagsToSend,
        "dietTags": dietTagsToSend,
        "regionTags": regionTagsToSend,
        "dishtypeTags": dishtypeTagsToSend
      };

      final result =
          await RecipeService.createRecipe(recipeData, _selectedImage!);

      if (result['success'] == true) {
        _showSnackBar("Tạo công thức thành công!");
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar(result['message'] ?? "Có lỗi xảy ra", isError: true);
      }
    } catch (e) {
      _showSnackBar("Lỗi: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kColorError : kColorPrimary,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> difficultyOptions = _apiDifficultyTags.isNotEmpty
        ? _apiDifficultyTags.map((e) => e['name'].toString()).toList()
        : ['Dễ', 'Trung bình', 'Khó'];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: AppBar(
          backgroundColor: kColorAppBar,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_rounded, color: kColorPrimaryText),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Tạo Công Thức',
              style: GoogleFonts.inter(
                  color: kColorPrimaryText, fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: _nameController,
                        label: 'Tên món ăn',
                        hint: 'Ví dụ: Phở bò tái'),
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
                    _buildDropdownField(
                      label: 'Độ khó',
                      value: _selectedDifficulty,
                      items: difficultyOptions,
                      onChanged: (v) => setState(() => _selectedDifficulty = v),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Phân loại (Tags)'),
                    _buildDynamicCategorySection(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Nguyên liệu'),
                    _buildIngredientList(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: kColorPrimary),
                      label: Text('Thêm dòng',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: kColorPrimary)),
                      onPressed: _addIngredientRow,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _stepsController,
                      label: 'Cách làm (Các bước)',
                      hint:
                          'Mỗi bước 1 dòng.\nVD:\nB1: Rửa rau\nB2: Luộc thịt...',
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Video hướng dẫn'),
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

  Widget _buildVideoSelectionSection() {
    return Column(
      children: [
        _buildVideoPicker(),
        const SizedBox(height: 12),
        Center(
            child: Text("- HOẶC -",
                style: TextStyle(color: kColorSecondaryText, fontSize: 12))),
        const SizedBox(height: 12),
        TextFormField(
          controller: _videoUrlController,
          keyboardType: TextInputType.url,
          onChanged: (value) {
            if (value.isNotEmpty && _selectedVideo != null) {
              setState(() => _selectedVideo = null);
            }
          },
          decoration: InputDecoration(
            labelText: 'Link YouTube/TikTok',
            hintText: 'https://youtube.com/...',
            filled: true,
            fillColor: kColorCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabled: _selectedVideo == null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kColorBorder)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
            color: kColorCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kColorBorder, width: 2),
            image: _selectedImage != null
                ? DecorationImage(
                    image: FileImage(_selectedImage!), fit: BoxFit.cover)
                : null),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: kColorSecondaryText, size: 48),
                  Text('Chạm để chọn ảnh bìa',
                      style: GoogleFonts.inter(color: kColorSecondaryText)),
                ],
              )
            : null,
      ),
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
          boxShadow: _selectedVideo != null
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
                color: _selectedVideo != null
                    ? kColorPrimary.withOpacity(0.1)
                    : kColorBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedVideo != null
                    ? Icons.videocam
                    : Icons.video_library_outlined,
                color: _selectedVideo != null
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
                    _selectedVideo != null
                        ? 'Đã chọn video từ máy'
                        : 'Tải video lên từ thư viện',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: kColorPrimaryText,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedVideo != null
                        ? _selectedVideo!.path.split('/').last
                        : 'Chạm để chọn (sẽ xoá link Youtube nếu có)',
                    style: GoogleFonts.inter(
                        color: kColorSecondaryText, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_selectedVideo != null)
              IconButton(
                icon: const Icon(Icons.close, color: kColorError),
                onPressed: _removeVideo,
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCategorySection() {
    if (_isTagsLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_apiMealTimeTags.isNotEmpty) ...[
            Text('Bữa ăn',
                style: GoogleFonts.inter(
                    color: kColorPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _apiMealTimeTags.map((tagObj) {
                final tagName = tagObj['name'];
                final isSelected = _selectedTags.contains(tagName);
                return FilterChip(
                  label: Text(tagName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedTags.add(tagName);
                      else
                        _selectedTags.remove(tagName);
                    });
                  },
                  selectedColor: kColorPrimary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kColorPrimaryText),
                  backgroundColor: kColorBackground,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_apiDietTags.isNotEmpty) ...[
            Text('Chế độ ăn',
                style: GoogleFonts.inter(
                    color: kColorPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _apiDietTags.map((tagObj) {
                final tagName = tagObj['name'];
                final isSelected = _selectedTags.contains(tagName);
                return FilterChip(
                  label: Text(tagName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedTags.add(tagName);
                      else
                        _selectedTags.remove(tagName);
                    });
                  },
                  selectedColor: kColorPrimary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kColorPrimaryText),
                  backgroundColor: kColorBackground,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_apiRegionTags.isNotEmpty) ...[
            Text('Vùng miền',
                style: GoogleFonts.inter(
                    color: kColorPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _apiRegionTags.map((tagObj) {
                final tagName = tagObj['name'];
                final isSelected = _selectedTags.contains(tagName);
                return FilterChip(
                  label: Text(tagName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedTags.add(tagName);
                      else
                        _selectedTags.remove(tagName);
                    });
                  },
                  selectedColor: kColorPrimary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kColorPrimaryText),
                  backgroundColor: kColorBackground,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_apiDishTypeTags.isNotEmpty) ...[
            Text('Cách chế biến',
                style: GoogleFonts.inter(
                    color: kColorPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _apiDishTypeTags.map((tagObj) {
                final tagName = tagObj['name'];
                final isSelected = _selectedTags.contains(tagName);
                return FilterChip(
                  label: Text(tagName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedTags.add(tagName);
                      else
                        _selectedTags.remove(tagName);
                    });
                  },
                  selectedColor: kColorPrimary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kColorPrimaryText),
                  backgroundColor: kColorBackground,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _ingredientRows.length,
      itemBuilder: (context, index) {
        return _buildIngredientRow(index);
      },
    );
  }

  Widget _buildIngredientRow(int index) {
    final rowController = _ingredientRows[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TypeAheadField<Map<String, dynamic>>(
              controller: rowController.name,
              hideOnEmpty: false, // Hiện dropdown kể cả khi mảng rỗng
              emptyBuilder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Không tìm thấy nguyên liệu này!',
                    style: GoogleFonts.inter(color: kColorError, fontSize: 13),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.length < 2) return [];
                return await RecipeService.searchMasterIngredients(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['name'],
                      style: GoogleFonts.inter(fontSize: 14)),
                  dense: true,
                );
              },
              onSelected: (suggestion) {
                setState(() {
                  rowController.name.text = suggestion['name'];
                  rowController.isVerified = true;
                });
                _resetNutritionStatus();
              },
              builder: (context, controller, focusNode) {
                // Xác định nếu user đã nhập text nhưng isVerified = false (lỗi)
                bool hasError = controller.text.isNotEmpty && !rowController.isVerified;

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (val) {
                    setState(() {
                      rowController.isVerified = false;
                    });
                    _resetNutritionStatus();
                  },
                  decoration: InputDecoration(
                    labelText: 'Tên nguyên liệu',
                    hintText: 'VD: Thịt gà',
                    filled: true,
                    // Nếu lỗi thì nền đổi sang màu đỏ nhạt để cảnh báo
                    fillColor: hasError ? kColorError.withOpacity(0.05) : kColorCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    // Bo viền đỏ nếu lỗi
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: hasError ? kColorError : kColorBorder, 
                            width: hasError ? 1.5 : 1)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: hasError ? kColorError : kColorBorder, 
                            width: hasError ? 1.5 : 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: hasError ? kColorError : kColorPrimary, 
                            width: 2)),
                    // Hiện icon đỏ báo lỗi
                    suffixIcon: hasError 
                        ? const Icon(Icons.error_outline, color: kColorError, size: 20) 
                        : null,
                  ),
                );
              },
              decorationBuilder: (context, child) {
                return Material(
                  type: MaterialType.card,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _buildTextField(
                  controller: rowController.quantity,
                  label: 'SL',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _resetNutritionStatus())),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _buildTextField(
                  controller: rowController.weight,
                  label: 'Khối lượng',
                  hint: '200',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _resetNutritionStatus())),
          const SizedBox(width: 8),

          // --- DROPDOWN ĐƠN VỊ KÍCH THƯỚC NHỎ ---
          SizedBox(
            width: 85,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              value: kUnitOptions.contains(rowController.unit.text)
                  ? rowController.unit.text
                  : null,
              decoration: InputDecoration(
                labelText: 'Đơn vị',
                filled: true,
                fillColor: kColorCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kColorBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kColorBorder)),
              ),
              items: kUnitOptions.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                return kUnitOptions.map((String unit) {
                  return Text(
                    unit,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              onChanged: (String? newValue) {
                if (newValue != null) {
                  rowController.unit.text = newValue;
                  _resetNutritionStatus();
                }
              },
            ),
          ),

          if (_ingredientRows.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: kColorError),
              onPressed: () => _removeIngredientRow(index),
            )
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    int servings = int.tryParse(_selectedServings?.split(' ')[0] ?? "1") ?? 1;
    if (servings < 1) servings = 1;

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _analyzeNutrition,
          icon: Icon(Icons.analytics_outlined,
              color: _isNutritionAnalyzed ? kColorPrimary : kColorSecondary),
          label: Text(
              _isNutritionAnalyzed
                  ? 'Đã phân tích (Nhấn để làm lại)'
                  : 'Phân tích Dinh dưỡng (AI)',
              style: TextStyle(
                  color: _isNutritionAnalyzed ? kColorPrimary : kColorSecondary,
                  fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(
                color: _isNutritionAnalyzed ? kColorPrimary : kColorSecondary,
                width: 2),
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
                      _buildNutritionRow('Muối', _nutritionData!['sodium'] ?? 0,
                          'mg', servings),
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
            child:
                Text(label, style: const TextStyle(color: kColorSecondaryText)),
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
    double safeParse(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    double protein = safeParse(_nutritionData!['protein']);
    double carbs = safeParse(_nutritionData!['carbs']);
    double fat = safeParse(_nutritionData!['fat']);

    double total = protein + carbs + fat;

    if (total <= 0) {
      return PieChart(PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: 100,
            color: Colors.grey.shade300,
            radius: 50,
            title: '',
            showTitle: false,
          ),
        ],
      ));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: protein,
            color: kColorProtein,
            title: '${((protein / total) * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: carbs,
            color: kChartCarbs,
            title: '${((carbs / total) * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: fat,
            color: kChartFat,
            title: '${((fat / total) * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      TextInputType keyboardType = TextInputType.text,
      int? minLines = 1,
      int? maxLines = 1,
      TextInputAction? textInputAction,
      Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
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
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kColorBorder)),
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Nhập thông tin' : null,
    );
  }

  Widget _buildDropdownField(
      {required String label,
      required List<String> items,
      required String? value,
      required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kColorCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kColorBorder))),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map((String e) {
          return Text(
            e,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          );
        }).toList();
      },
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: GoogleFonts.inter(
              color: kColorSecondaryText, fontWeight: FontWeight.bold)),
    );
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
            onPressed: _submitRecipe,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50), backgroundColor: kColorPrimary),
            child: const Text('Đăng công thức',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}