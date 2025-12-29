import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Định nghĩa màu sắc (trích xuất từ theme) ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // --- State (Trạng thái) cho các lựa chọn filter ---
  final List<String> _selectedMealTimes = [];
  final List<String> _selectedIngredients = [];
  final List<String> _selectedDiets = [];
  final List<String> _selectedExclusions = [];
  String? _selectedCookingTime;
  final List<String> _selectedMedicalDiets = [];

  // --- Dữ liệu (options) cho các bộ lọc ---
  static const List<String> _mealTimeOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack'
  ];
  static const List<String> _dietOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'High-Protein'
  ];
  static const List<String> _cookingTimeOptions = [
    'Under 15 min',
    '15-30 min',
    '30-60 min',
    'Over 1 hour'
  ];
  static const List<String> _medicalDietOptions = [
    'Diabetic-Friendly',
    'Heart-Healthy',
    'Low-Sodium',
    'Low-Fat',
    'High-Fiber',
    'Anti-Inflammatory'
  ];

  // Hàm để xóa tất cả lựa chọn
  void _clearAllFilters() {
    setState(() {
      _selectedMealTimes.clear();
      _selectedIngredients.clear();
      _selectedDiets.clear();
      _selectedExclusions.clear();
      _selectedCookingTime = null;
      _selectedMedicalDiets.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kColorBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        // Thanh điều hướng dưới cùng chứa các nút hành động
        bottomNavigationBar: _buildBottomActions(context),
      ),
    );
  }

  // --- CÁC HÀM XÂY DỰNG UI ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kColorBackground,
      automaticallyImplyLeading: false,
      elevation: 1.0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: kColorPrimaryText,
          size: 24.0,
        ),
        onPressed: () {
          Navigator.of(context).pop(); // Quay lại trang trước
        },
      ),
      title: Text(
        'Filter',
        style: GoogleFonts.interTight(
          color: kColorPrimaryText,
          fontWeight: FontWeight.w600,
          fontSize: 22.0, // titleLarge
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.search_sharp,
              color: kColorPrimaryText,
              size: 24.0,
            ),
            onPressed: () {
              print('IconButton pressed ...');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      top: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Filter Recipes',
                style: GoogleFonts.interTight(
                  color: kColorPrimaryText,
                  fontSize: 28.0, // headlineMedium
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Phần 1: Meal Time
            _buildSectionTitle('Meal Time'),
            _buildChipGroup(
              _mealTimeOptions,
              _selectedMealTimes,
              (isSelected, option) {
                setState(() {
                  isSelected
                      ? _selectedMealTimes.add(option)
                      : _selectedMealTimes.remove(option);
                });
              },
            ),
            // Phần 3: Diet Type
            _buildSectionTitle('Diet Type'),
            _buildChipGroup(
              _dietOptions,
              _selectedDiets,
              (isSelected, option) {
                setState(() {
                  isSelected
                      ? _selectedDiets.add(option)
                      : _selectedDiets.remove(option);
                });
              },
            ),

            // Phần 5: Cooking Time (Chọn 1)
            _buildSectionTitle('Cooking Time'),
            _buildSingleChipGroup(
              _cookingTimeOptions,
              _selectedCookingTime,
              (isSelected, option) {
                setState(() {
                  // Nếu chọn, đặt làm giá trị; nếu bỏ chọn, đặt là null
                  _selectedCookingTime = isSelected ? option : null;
                });
              },
            ),

            // Phần 6: Medical Diet Foods
            _buildSectionTitle('Medical Diet Foods'),
            _buildChipGroup(
              _medicalDietOptions,
              _selectedMedicalDiets,
              (isSelected, option) {
                setState(() {
                  isSelected
                      ? _selectedMedicalDiets.add(option)
                      : _selectedMedicalDiets.remove(option);
                });
              },
            ),

            // Đệm dưới cùng để không bị che bởi BottomAppBar
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  // Hàm trợ giúp cho Tiêu đề
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.interTight(
              color: kColorPrimaryText,
              fontWeight: FontWeight.w600,
              fontSize: 18.0, // titleMedium
            ),
          ),
          const SizedBox(height: 12.0),
          const Divider(thickness: 1.0, color: kColorPrimaryText, height: 1.0),
        ],
      ),
    );
  }

  // Hàm trợ giúp cho nhóm CHỌN NHIỀU
  Widget _buildChipGroup(
    List<String> options,
    List<String> selectedValues,
    Function(bool, String) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: options.map((option) {
          final isSelected = selectedValues.contains(option);
          return _buildChip(
            label: option,
            isSelected: isSelected,
            onTap: (selected) {
              onSelected(selected, option);
            },
          );
        }).toList(),
      ),
    );
  }

  // Hàm trợ giúp cho nhóm CHỌN MỘT
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
          return _buildChip(
            label: option,
            isSelected: isSelected,
            onTap: (selected) {
              onSelected(selected, option);
            },
          );
        }).toList(),
      ),
    );
  }

  // Hàm trợ giúp để TẠO GIAO DIỆN một chip
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Function(bool) onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onTap(selected);
      },
      // --- Styling ---
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : kColorPrimaryText,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: kColorCard,
      selectedColor: kColorPrimary,
      showCheckmark: false,
      elevation: isSelected ? 2.0 : 0.0,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? kColorPrimary : kColorBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    );
  }

  // Hàm trợ giúp cho các nút bấm dưới cùng
  Widget _buildBottomActions(BuildContext context) {
    return BottomAppBar(
      color: kColorBackground,
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nút Clear All
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: kColorSecondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
              ),
            ),
            // Nút Show Recipes
            ElevatedButton(
              onPressed: () {
                print('Show Recipes pressed');
                // TODO: Áp dụng filter và quay lại
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              ),
              child: Text(
                'Show 123 Recipes', // TODO: Cập nhật số lượng này
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}