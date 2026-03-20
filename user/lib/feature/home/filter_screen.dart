import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';

// --- Định nghĩa màu sắc ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);

class FilterScreen extends StatefulWidget {
  final Map<String, List<String>>? currentFilters;
  
  const FilterScreen({super.key, this.currentFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool _isLoading = true;
  int _totalMatch = 0; 
  bool _isCounting = false;

  // --- Dữ liệu từ API ---
  List<dynamic> _apiMealTimeTags = [];
  List<dynamic> _apiDietTags = [];
  List<dynamic> _apiRegionTags = [];
  List<dynamic> _apiDishTypeTags = [];
  // ✅ [MỚI] List tag độ khó từ API
  List<dynamic> _apiDifficultyTags = [];

  // --- State lựa chọn (Lưu ID cho Tags, String cho Enum) ---
  final List<String> _selectedMealTimeIds = [];
  final List<String> _selectedDietIds = [];
  final List<String> _selectedRegionIds = [];
  final List<String> _selectedDishTypeIds = [];
  
  // ✅ [MỚI] Biến lưu độ khó đã chọn (Single Select)
  String? _selectedDifficulty;

  // Cooking time (Hardcoded)
  String? _selectedCookingTime;
  static const List<String> _cookingTimeOptions = [
    'Under 15 min',
    '15-30 min',
    '30-60 min',
    'Over 1 hour'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentFilters != null) {
      _selectedMealTimeIds.addAll(widget.currentFilters!['mealTimeTags'] ?? []);
      _selectedDietIds.addAll(widget.currentFilters!['dietTags'] ?? []);
      _selectedRegionIds.addAll(widget.currentFilters!['regionTags'] ?? []);
      _selectedDishTypeIds.addAll(widget.currentFilters!['dishtypeTags'] ?? []);
      
      // ✅ [MỚI] Khôi phục độ khó nếu có (Lấy phần tử đầu tiên vì map lưu List)
      if (widget.currentFilters!['difficulty'] != null && 
          widget.currentFilters!['difficulty']!.isNotEmpty) {
        _selectedDifficulty = widget.currentFilters!['difficulty']!.first;
      }
    }
    _fetchTags();
    _checkResultCount();
  }

  Future<void> _checkResultCount() async {
    if (!mounted) return;
    setState(() => _isCounting = true);

    try {
      String? mealTimeTags = _selectedMealTimeIds.isNotEmpty ? _selectedMealTimeIds.join(',') : null;
      String? dietTags = _selectedDietIds.isNotEmpty ? _selectedDietIds.join(',') : null;
      String? regionTags = _selectedRegionIds.isNotEmpty ? _selectedRegionIds.join(',') : null;
      String? dishtypeTags = _selectedDishTypeIds.isNotEmpty ? _selectedDishTypeIds.join(',') : null;

      final result = await RecipeService.getAllRecipes(
        limit: 1, 
        mealTimeTags: mealTimeTags,
        dietTags: dietTags,
        regionTags: regionTags,
        dishtypeTags: dishtypeTags,
        // ✅ [MỚI] Gửi thêm tham số difficulty
        difficulty: _selectedDifficulty,
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _totalMatch = result['meta']?['total'] ?? 0;
        });
      }
    } catch (e) {
      print("Lỗi đếm kết quả: $e");
    } finally {
      if (mounted) setState(() => _isCounting = false);
    }
  }

  Future<void> _fetchTags() async {
    try {
      final result = await RecipeService.getCreateOptions();
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            final data = result['data'];
            _apiMealTimeTags = data['mealTimeTags'] ?? [];
            _apiDietTags = data['dietTags'] ?? [];
            _apiRegionTags = data['regionTags'] ?? [];
            _apiDishTypeTags = data['dishtypeTags'] ?? [];
            // ✅ [MỚI] Lấy tag độ khó
            _apiDifficultyTags = data['difficultyTags'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải tags: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedMealTimeIds.clear();
      _selectedDietIds.clear();
      _selectedRegionIds.clear();
      _selectedDishTypeIds.clear();
      _selectedCookingTime = null;
      // ✅ [MỚI] Xóa độ khó
      _selectedDifficulty = null;
    });
    _checkResultCount(); 
  }

  void _applyFilters() {
    final filters = {
      'mealTimeTags': _selectedMealTimeIds,
      'dietTags': _selectedDietIds,
      'regionTags': _selectedRegionIds,
      'dishtypeTags': _selectedDishTypeIds,
      // ✅ [MỚI] Đóng gói độ khó vào List để đồng bộ kiểu Map<String, List>
      if (_selectedDifficulty != null) 'difficulty': [_selectedDifficulty!],
    };
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: _buildAppBar(context),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
            : _buildBody(context),
        bottomNavigationBar: _buildBottomActions(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kColorBackground,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: kColorPrimaryText, size: 24.0),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Bộ lọc tìm kiếm',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearAllFilters,
          child: Text('Đặt lại', 
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    // ✅ [MỚI] Chuẩn bị danh sách options cho độ khó
    // Nếu API trả về tag thì lấy name, nếu không thì dùng mặc định
    final List<String> difficultyOptions = _apiDifficultyTags.isNotEmpty 
        ? _apiDifficultyTags.map((e) => e['name'].toString()).toList()
        : ['Dễ', 'Trung bình', 'Khó'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // ✅ [MỚI] Thêm phần chọn Độ khó (Single Select)
            _buildSectionTitle('Độ khó'),
            _buildSingleChipGroup(
              difficultyOptions,
              _selectedDifficulty,
              (isSelected, option) {
                setState(() => _selectedDifficulty = isSelected ? option : null);
                _checkResultCount();
              },
            ),

            _buildSectionTitle('Giờ ăn'),
            _buildDynamicChipGroup(_apiMealTimeTags, _selectedMealTimeIds),

            _buildSectionTitle('Thời gian nấu'),
            _buildSingleChipGroup(
              _cookingTimeOptions,
              _selectedCookingTime,
              (isSelected, option) {
                setState(() => _selectedCookingTime = isSelected ? option : null);
                // Note: Hiện tại API chưa lọc theo cooking time string này, cần mapping thêm nếu muốn
              },
            ),

            _buildSectionTitle('Chế độ ăn kiêng'),
            _buildDynamicChipGroup(_apiDietTags, _selectedDietIds),

            _buildSectionTitle('Vùng miền'),
            _buildDynamicChipGroup(_apiRegionTags, _selectedRegionIds),

            _buildSectionTitle('Cách chế biến'),
            _buildDynamicChipGroup(_apiDishTypeTags, _selectedDishTypeIds),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
      child: Text(
        title,
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
        ),
      ),
    );
  }

  // Widget dùng cho Multi-Select (Tags)
  Widget _buildDynamicChipGroup(List<dynamic> apiData, List<String> selectedIds) {
    if (apiData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text("Đang cập nhật...", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: apiData.map((item) {
          final String name = item['name'];
          final String id = item['_id'];
          final bool isSelected = selectedIds.contains(id);

          return FilterChip(
            label: Text(name),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  selectedIds.add(id);
                } else {
                  selectedIds.remove(id);
                }
              });
              _checkResultCount();
            },
            labelStyle: GoogleFonts.inter(
              color: isSelected ? Colors.white : kColorPrimaryText,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: kColorCard,
            selectedColor: kColorPrimary,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? kColorPrimary : kColorBorder,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          );
        }).toList(),
      ),
    );
  }

  // Widget dùng cho Single-Select (Độ khó, Thời gian)
  Widget _buildSingleChipGroup(
    List<String> options,
    String? selectedValue,
    Function(bool, String) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: options.map((option) {
          final isSelected = (selectedValue == option);
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (selected) => onSelected(selected, option),
            labelStyle: GoogleFonts.inter(
              color: isSelected ? Colors.white : kColorPrimaryText,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: kColorCard,
            selectedColor: kColorPrimary,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? kColorPrimary : kColorBorder,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kColorCard,
        border: Border(top: BorderSide(color: kColorBorder)),
      ),
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: kColorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          elevation: 0,
        ),
        
        child: _isCounting 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            )
          : Text(
              'Xem ($_totalMatch) kết quả',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
      ),
    );
  }
}