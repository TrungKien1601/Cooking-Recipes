import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../home/homepage_screen.dart';

// --- ĐỊNH NGHĨA MÀU SẮC ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorBorder = Color(0xFFE0E3E7);
const Color kColorError = Color(0xFFFF5963);
const Color kColorInfo = Colors.white;
const Color kChartFat = Color(0xFFFBC02D);
const Color kChartCarbs = Color(0xFF0288D1);
const Color kChartProtein = Color(0xFFE64A19);

class OnboardingFlowScreen extends StatefulWidget {
  final String? userId;

  const OnboardingFlowScreen({super.key, this.userId});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 9;

  // --- DỮ LIỆU FORM ---
  final Map<String, dynamic> _formData = {
    'gender': null,
    'age': '',
    'height': 160.0,
    'weight': 60.0,
    'target_weight': 60.0,
    'healthConditions': <String>[],
    'goal': null,
    'diets': null,
    'habits': <String>[],
    'exclusions': <String>[], 
    'food_restrictions': '',
  };

  // --- CONTROLLERS ---
  final _page2Key = GlobalKey<FormState>();
  final _page3Key = GlobalKey<FormState>();
  final _pageGoalKey = GlobalKey<FormState>();

  late TextEditingController _ageController;
  late TextEditingController _restrictionsController;

  // --- DỮ LIỆU OPTIONS ---
  List<String> _healthConditionOptions = [];
  List<String> _habitOptions = [];
  List<String> _goalOptions = [];
  List<String> _dietOptions = [];
  List<String> _exclusionOptions = [];
  final List<String> _genderOptions = ['Nam', 'Nữ', 'Khác'];

  // --- STATE ---
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiData;
  String _currentUserId = "";
  String _bmiResult = "";

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _restrictionsController = TextEditingController();

    _fetchOptionsFromServer();
    _loadUserId();
    _calculateBmi();
  }

  // --- ✅ HÀM MỚI: Ép kiểu an toàn để tránh crash khi AI trả về String ---
  double _parseSafeNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble(); // Nếu là số thì lấy luôn
    if (value is String) {
      // Nếu là chuỗi (VD: "50g", "approx 50"), xóa hết chữ, chỉ giữ lại số
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadUserId() async {
    try {
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        setState(() => _currentUserId = widget.userId!);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString('userId');

      if (savedId == null) {
        String? userDataString = prefs.getString('user_data');
        if (userDataString != null) {
          final data = jsonDecode(userDataString);
          savedId = data['_id'] ?? data['id'];
        }
      }

      if (savedId != null) {
        setState(() => _currentUserId = savedId!);
      }
    } catch (e) {
      debugPrint("❌ Lỗi tải userId: $e");
    }
  }

  Future<void> _fetchOptionsFromServer() async {
    try {
      final service = AuthService();
      final options = await service.getSurveyOptions();

      if (mounted) {
        setState(() {
          // Lấy dữ liệu từ server
          _healthConditionOptions = List<String>.from(options['healthConditions'] ?? []);
          _habitOptions = List<String>.from(options['habits'] ?? []);
          _goalOptions = List<String>.from(options['goals'] ?? []);
          _dietOptions = List<String>.from(options['diets'] ?? []);
          _exclusionOptions = List<String>.from(options['exclusions'] ?? []);

          // // --- LOGIC FALLBACK (QUAN TRỌNG) ---
          // if (_goalOptions.isEmpty) {
          //   _goalOptions = [
          //     "Giảm cân", "Tăng cơ", "Tăng cân lành mạnh", "Duy trì vóc dáng",
          //     "Cải thiện tiêu hóa", "Tăng cường hệ miễn dịch", "Đẹp da & Chống lão hóa",
          //     "Tăng cường năng lượng", "Cải thiện giấc ngủ", "Thanh lọc cơ thể (Detox)"
          //   ];
          // }

          // if (_exclusionOptions.isEmpty) {
          //   _exclusionOptions = [
          //     "Không chứa Gluten", "Dị ứng đậu phộng", "Không đường sữa (Lactose-free)",
          //     "Dị ứng hải sản", "Dị ứng trứng", "Dị ứng đậu nành", "Không hành tỏi (Ngũ vị tân)",
          //     "Không cồn", "Không Caffeine", "Kiêng thịt heo", "Kiêng thịt bò"
          //   ];
          // }

          // if (_dietOptions.isEmpty) {
          //   _dietOptions = [
          //     "Keto", "Ăn chay (Vegetarian)", "Thuần chay (Vegan)", "Eat Clean",
          //     "Low Carb", "Địa Trung Hải (Mediterranean)", "Paleo", 
          //     "Nhịn ăn gián đoạn (Intermittent Fasting)", "DASH (Ngăn ngừa cao huyết áp)", 
          //     "Thực dưỡng (Macrobiotic)", "GM Diet"
          //   ];
          // }
          
          // if (_healthConditionOptions.isEmpty) {
          //    _healthConditionOptions = ["Tiểu đường", "Cao huyết áp", "Tim mạch", "Dạ dày", "Không có"];
          // }

          // Gán giá trị mặc định cho Dropdown
          if (_formData['goal'] == null && _goalOptions.isNotEmpty) {
            _formData['goal'] = _goalOptions.first;
          }
          if (_formData['diets'] == null && _dietOptions.isNotEmpty) {
            _formData['diets'] = _dietOptions.first;
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch options: $e");
    }
  }

  void _calculateBmi() {
    final double height = _formData['height'];
    final double weight = _formData['weight'];

    if (height > 0 && weight > 0) {
      final double heightInMeters = height / 100.0;
      final double bmi = weight / (heightInMeters * heightInMeters);

      String category;
      if (bmi < 18.5) {
        category = "Thiếu cân";
      } else if (bmi >= 18.5 && bmi < 24.9) {
        category = "Bình thường";
      } else if (bmi >= 25 && bmi < 29.9) {
        category = "Thừa cân";
      } else if (bmi >= 30 && bmi < 34.9) {
        category = "Béo phì loại 1";
      } else {
        category = "Béo phì loại 2";
      }

      setState(() {
        _bmiResult = "${bmi.toStringAsFixed(1)} ($category)";
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNextPressed() {
    FocusScope.of(context).unfocus();

    bool isValid = true;
    switch (_currentPage) {
      case 1:
        isValid = _page2Key.currentState!.validate();
        break;
      case 2:
        isValid = _page3Key.currentState!.validate();
        if (isValid)
          _formData['age'] = int.tryParse(_ageController.text) ?? 20;
        break;
      case 5:
        _formData['food_restrictions'] = _restrictionsController.text.trim();
        break;
      case 6:
        isValid = _pageGoalKey.currentState!.validate();
        break;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: kColorError));
      return;
    }

    if (_currentPage == 6) {
      _runAiAnalysis();
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
  // 1. Lưu trạng thái đã làm xong vào máy
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isSurveyDone', true); 

  // 2. Chuyển trang
  if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }
}

  Future<void> _runAiAnalysis() async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Lỗi: Không tìm thấy ID người dùng. Hãy đăng nhập lại!"),
            backgroundColor: kColorError),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiData = null;
    });

    final authService = AuthService();

    // --- ✅ FIX 1: Chuẩn bị dữ liệu trước khi gửi ---
    // Copy ra một map mới để tránh làm hỏng state gốc của UI
    final Map<String, dynamic> dataToSend = Map.from(_formData);

    // FIX: Chuyển 'diets' từ String sang List<String> để khớp với Backend
    if (dataToSend['diets'] != null && dataToSend['diets'] is String) {
      dataToSend['diets'] = [dataToSend['diets']];
    } else {
      dataToSend['diets'] = [];
    }

    // FIX: Đảm bảo target_weight được gửi đi (nếu service có nhận)
    // Lưu ý: Bạn cần vào user_service.dart thêm dòng 'target_weight': formData['target_weight'] vào bodyData nếu muốn lưu.
    
    // Gọi API Backend
    final result = await authService.submitSurvey(_currentUserId, dataToSend);

    if (result != null) {
      setState(() {
        _aiData = result;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lỗi kết nối AI hoặc Server quá tải. Vui lòng thử lại!"),
            backgroundColor: kColorError),
      );
    }

    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        backgroundColor: kColorBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: List.generate(_totalPages, (index) {
            return Expanded(
              child: Container(
                height: 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color:
                      _currentPage >= index ? kColorPrimary : kColorBorder,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            );
          }),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildPage_Intro(), // 0
          _buildPage_Gender(), // 1
          _buildPage_Age(), // 2
          _buildPage_BodyStats(), // 3
          _buildPage_TargetWeight(), // 4
          _buildPage_HealthAndHabits(), // 5
          _buildPage_Goal(), // 6
          _buildPage_AiAnalysis(), // 7
          _buildPage_Done(), // 8
        ],
      ),
      bottomNavigationBar: Container(
        color: kColorCard,
        padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0,
            MediaQuery.of(context).padding.bottom + 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: _currentPage == 0 ? 0.0 : 1.0,
              child: OutlinedButton(
                onPressed: _currentPage == 0 ? null : _onBackPressed,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 50),
                  foregroundColor: kColorSecondaryText,
                  side: const BorderSide(color: kColorBorder, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                child: Text('Back',
                    style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600, fontSize: 16.0)),
              ),
            ),
            ElevatedButton(
              onPressed: (_currentPage == 7 && _isAnalyzing)
                  ? null
                  : _onNextPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 50),
                backgroundColor: kColorPrimary,
                foregroundColor: kColorInfo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? 'Enter App' : 'Next',
                style: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600, fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CÁC TRANG ---

  Widget _buildPage_Intro() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              color: kColorPrimary, size: 80.0),
          const SizedBox(height: 24.0),
          Text('Chào Mừng tới CookingRecipes!',
              textAlign: TextAlign.center,
              style: GoogleFonts.interTight(
                  color: kColorPrimaryText,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16.0),
          Text(
              'Trước khi bắt đầu, hãy cá nhân hóa trải nghiệm của bạn để nhận được gợi ý tốt nhất.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 16.0, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPage_Gender() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
          key: _page2Key,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader("Giới tính của bạn?",
                    "Điều này giúp tính toán nhu cầu dinh dưỡng."),
                const SizedBox(height: 32.0),
                _buildDropdownField(
                    label: 'Giới tính',
                    hint: 'Chọn một tùy chọn',
                    value: _formData['gender'],
                    items: _genderOptions,
                    onChanged: (value) =>
                        setState(() => _formData['gender'] = value))
              ])),
    );
  }

  Widget _buildPage_Age() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
          key: _page3Key,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader("Bạn bao nhiêu tuổi?",
                    "Tuổi tác giúp tùy chỉnh kế hoạch ăn uống."),
                const SizedBox(height: 32.0),
                _buildTextField(
                    controller: _ageController,
                    label: 'Tuổi',
                    hint: 'VD: 25',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'Vui lòng nhập tuổi'
                            : null)
              ])),
    );
  }

  Widget _buildPage_BodyStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader("Chỉ số cơ thể",
            "Nhập chiều cao và cân nặng để tính BMI.",
            isDark: false),
        const SizedBox(height: 32.0),
        _buildNumberSlider(
            currentValue: _formData['height'],
            minValue: 100,
            maxValue: 250,
            unit: 'cm',
            onChanged: (value) {
              setState(() => _formData['height'] = value);
              _calculateBmi();
            }),
        const SizedBox(height: 24.0),
        const Divider(color: kColorBorder, height: 1),
        const SizedBox(height: 24.0),
        _buildNumberSlider(
            currentValue: _formData['weight'],
            minValue: 30,
            maxValue: 200,
            unit: 'kg',
            onChanged: (value) {
              setState(() => _formData['weight'] = value);
              _calculateBmi();
            }),
        const SizedBox(height: 32.0),
        if (_bmiResult.isNotEmpty)
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: kColorCard,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: kColorPrimary, width: 1.0)),
              child: Column(children: [
                Text("BMI Tạm tính (Chỉ số khối cơ thể)",
                    style: GoogleFonts.inter(
                        color: kColorSecondaryText, fontSize: 14.0)),
                const SizedBox(height: 8.0),
                Text(_bmiResult,
                    style: GoogleFonts.interTight(
                        color: kColorPrimary,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w600))
              ]))
      ]),
    );
  }

  Widget _buildPage_TargetWeight() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader("Cân nặng mục tiêu?",
            "Điều này giúp chúng tôi đề xuất thực đơn phù hợp.",
            isDark: false),
        const SizedBox(height: 40.0),
        _buildNumberSlider(
            currentValue: _formData['target_weight'],
            minValue: 30,
            maxValue: 200,
            unit: 'kg',
            onChanged: (value) =>
                setState(() => _formData['target_weight'] = value))
      ]),
    );
  }

  // --- TRANG CHỌN THÔNG TIN SỨC KHỎE ---
  Widget _buildPage_HealthAndHabits() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
              "Sức khỏe & Thói quen", "Chọn những mục phù hợp (nếu có)."),
          const SizedBox(height: 32.0),
          
          _buildSectionTitle('Tình trạng sức khỏe'),
          _healthConditionOptions.isEmpty
              ? const Center(child: Text("Đang tải...", style: TextStyle(color: Colors.grey)))
              : _buildChipGroup(
                  _healthConditionOptions, _formData['healthConditions'],
                  (isSelected, option) {
                  setState(() {
                    isSelected
                        ? _formData['healthConditions'].add(option)
                        : _formData['healthConditions'].remove(option);
                  });
                }),
          const SizedBox(height: 24.0),
          
          _buildSectionTitle('Dị ứng / Kiêng kị'),
          _exclusionOptions.isEmpty 
            ? const Text("Không có dữ liệu", style: TextStyle(color: Colors.grey))
            : _buildChipGroup(
                _exclusionOptions, _formData['exclusions'],
                (isSelected, option) {
              setState(() {
                isSelected
                    ? _formData['exclusions'].add(option)
                    : _formData['exclusions'].remove(option);
              });
            }),
          const SizedBox(height: 24.0),
          
          _buildSectionTitle('Thói quen ăn uống'),
          _habitOptions.isEmpty
              ? const SizedBox.shrink()
              : _buildChipGroup(_habitOptions, _formData['habits'],
                  (isSelected, option) {
                  setState(() {
                    isSelected
                        ? _formData['habits'].add(option)
                        : _formData['habits'].remove(option);
                  });
                }),
          const SizedBox(height: 24.0),

          _buildSectionTitle('Chế độ ăn (Diet)'),
          _buildRadioGroup(
            label: 'Bạn theo chế độ nào?',
            options: _dietOptions,
            groupValue: _formData['diets'] ??
                (_dietOptions.isNotEmpty ? _dietOptions.first : ''),
            onChanged: (value) => setState(() {
              _formData['diets'] = value!;
              String valLower = value.toLowerCase();
              if (!valLower.contains('vegetarian') &&
                  !valLower.contains('vegan') &&
                  !valLower.contains('chay')) {
                _restrictionsController.clear();
                _formData['food_restrictions'] = '';
              }
            }),
          ),
          
          if (_formData['diets'] != null &&
              (_formData['diets'].toString().toLowerCase().contains("vegetarian") ||
                  _formData['diets'].toString().toLowerCase().contains("vegan") ||
                  _formData['diets'].toString().toLowerCase().contains("chay")))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextFormField(
                controller: _restrictionsController,
                decoration: InputDecoration(
                  labelText: 'Chi tiết chay (Quan trọng)',
                  hintText: 'VD: Kiêng hành tỏi, trứng, sữa...',
                  prefixIcon:
                      const Icon(Icons.edit_note, color: kColorPrimary),
                  filled: true,
                  fillColor: kColorCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: kColorBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                          color: kColorPrimary, width: 2.0)),
                ),
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage_Goal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _pageGoalKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader("Mục tiêu dinh dưỡng?",
              "Hãy cho biết mục tiêu chính của bạn."),
          const SizedBox(height: 32.0),
          _goalOptions.isEmpty
              ? const CircularProgressIndicator()
              : _buildDropdownField(
                  label: 'Mục tiêu',
                  hint: 'Chọn mục tiêu chính',
                  value: _formData['goal'],
                  items: _goalOptions,
                  onChanged: (value) =>
                      setState(() => _formData['goal'] = value))
        ]),
      ),
    );
  }

  // --- TRANG HIỂN THỊ KẾT QUẢ AI ---
  Widget _buildPage_AiAnalysis() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kColorPrimary),
            const SizedBox(height: 24.0),
            Text('AI đang tính toán thực đơn...',
                style: GoogleFonts.inter(
                    color: kColorSecondaryText, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Text('Vui lòng đợi trong giây lát...',
                style: GoogleFonts.inter(
                    color: kColorSecondaryText, fontSize: 12.0)),
          ],
        ),
      );
    }

    return _aiData == null
        ? const Center(child: Text("Chưa có dữ liệu phân tích"))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildAnalysisReport(),
          );
  }

  Widget _buildAnalysisReport() {
    // 1. Check null an toàn
    if (_aiData == null || _aiData!['nutrition'] == null) {
      return const SizedBox();
    }

    // 2. Lấy dữ liệu
    final nutrition = _aiData!['nutrition'];
    final recommendations = List<String>.from(_aiData!['recommendations'] ?? []);
    final foodsToAvoid = List<String>.from(_aiData!['foodsToAvoid'] ?? []);

    // --- ✅ CẬP NHẬT: Dùng _parseSafeNumber để tránh crash ---
    double pVal = _parseSafeNumber(nutrition['protein']);
    double cVal = _parseSafeNumber(nutrition['carbs']);
    double fVal = _parseSafeNumber(nutrition['fat']);

    // Nếu tổng bằng 0 (AI chưa tính kịp hoặc lỗi), ta gán giá trị mặc định để vẽ biểu đồ cho đẹp
    bool isDataEmpty = (pVal + cVal + fVal) == 0;
    
    if (isDataEmpty) {
       pVal = 30;
       cVal = 40;
       fVal = 30;
    }

    double totalVal = pVal + cVal + fVal;
    
    // Tính phần trăm
    double pPercent = (pVal / totalVal) * 100;
    double cPercent = (cVal / totalVal) * 100;
    double fPercent = (fVal / totalVal) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("AI Nutrition Analysis", "Kết quả phân tích dựa trên hồ sơ của bạn."),
        const SizedBox(height: 24.0),
        
        // --- Bảng thông số cơ bản ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
              color: kColorPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                // Sử dụng toString() an toàn
                child: _buildStatItem("BMI", "${nutrition['bmi'] ?? 0}",
                    nutrition['bmiStatus'] ?? ""),
              ),
              Expanded(
                child: _buildStatItem("Nước", nutrition['water'] ?? "2L", "/ngày"),
              ),
              Expanded(
                 // Sử dụng toString() an toàn
                child: _buildStatItem("Calo", "${nutrition['calories'] ?? 0}",
                    "kcal/ngày"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24.0),
        _buildSectionTitle('Tỷ lệ dinh dưỡng (Macros)'),
        
        // --- Biểu đồ tròn (Pie Chart) ---
        SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                startDegreeOffset: -90, // Xoay biểu đồ cho đẹp mắt hơn
                sections: [
                  PieChartSectionData(
                      color: kChartProtein,
                      value: pVal,
                      title: isDataEmpty ? 'Pro' : '${pPercent.round()}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(
                      color: kChartCarbs,
                      value: cVal,
                      title: isDataEmpty ? 'Carb' : '${cPercent.round()}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(
                      color: kChartFat,
                      value: fVal,
                      title: isDataEmpty ? 'Fat' : '${fPercent.round()}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                ],
              ),
              // Hiệu ứng hiện dần khi load xong
              swapAnimationDuration: const Duration(milliseconds: 800), 
              swapAnimationCurve: Curves.easeInOutQuad,
            )
        ),
        
        // Chú thích nhỏ nếu dữ liệu là giả lập
        if (isDataEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "(Dữ liệu mẫu do AI chưa cung cấp chi tiết macros)",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ),

        const SizedBox(height: 16.0),
        _buildPieChartLegend(),
        const SizedBox(height: 32.0),
        
        // --- Lời khuyên ---
        _buildSectionTitle('Lời khuyên từ chuyên gia'),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: kColorCard,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: kColorBorder)),
          child: Column(children: [
            _buildAnalysisItem(Icons.check_circle_outline, 'Nên làm:',
                recommendations, kColorPrimary),
          ]),
        ),
        
        const SizedBox(height: 16.0),
        
        // --- Món nên tránh ---
        if (foodsToAvoid.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: kColorError.withOpacity(0.3))),
            child: Column(children: [
              _buildAnalysisItem(Icons.warning_amber_rounded,
                  'Nên tránh:', foodsToAvoid, kColorError),
            ]),
          ),
        
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: kColorSecondaryText, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.interTight(
                color: kColorPrimaryText,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        if (sub.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: kColorSecondaryText, fontSize: 10)),
          ),
      ],
    );
  }

  Widget _buildPage_Done() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: kColorPrimary, size: 80.0),
            const SizedBox(height: 24.0),
            Text('Hoàn tất!',
                textAlign: TextAlign.center,
                style: GoogleFonts.interTight(
                    color: kColorPrimaryText,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16.0),
            Text(
                'Hồ sơ của bạn đã được lưu và phân tích. Hãy bắt đầu khám phá các món ăn phù hợp với bạn.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: kColorSecondaryText,
                    fontSize: 16.0,
                    height: 1.5))
          ]),
    );
  }

  Widget _buildHeader(String title, String subtitle, {bool isDark = false}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.interTight(
                  color: kColorPrimaryText,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8.0),
          Text(subtitle,
              style: GoogleFonts.inter(
                  color: kColorSecondaryText,
                  fontSize: 16.0,
                  height: 1.5))
        ]);
  }

  Widget _buildNumberSlider(
      {required double currentValue,
      required double minValue,
      required double maxValue,
      required String unit,
      required Function(double) onChanged}) {
    final int divisions = (maxValue - minValue) > 0
        ? (maxValue - minValue).toInt() * 2
        : 1;

    return Column(children: [
      Text('${currentValue.toStringAsFixed(1)} $unit',
          style: GoogleFonts.interTight(
              color: kColorPrimary,
              fontSize: 44.0,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 24.0),
      SliderTheme(
          data: SliderTheme.of(context).copyWith(
              activeTrackColor: kColorPrimary,
              inactiveTrackColor: kColorBorder,
              thumbColor: kColorCard,
              overlayColor: kColorPrimary.withOpacity(0.2),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12.0, elevation: 4)),
          child: Slider(
              value: currentValue,
              min: minValue,
              max: maxValue,
              divisions: divisions,
              label: currentValue.toStringAsFixed(1),
              onChanged: onChanged)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${minValue.toInt()}',
                    style: const TextStyle(color: kColorSecondaryText)),
                Text('${maxValue.toInt()}',
                    style: const TextStyle(color: kColorSecondaryText))
              ]))
    ]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(title,
            style: GoogleFonts.interTight(
                color: kColorPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16.0)));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      IconData? icon,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: kColorSecondaryText, size: 20)
                : null,
            filled: true,
            fillColor: kColorCard,
            contentPadding: const EdgeInsets.all(16.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: kColorBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                    color: kColorPrimary, width: 2.0))),
        validator: validator ??
            (value) => (value == null || value.isEmpty)
                ? 'Please enter this field'
                : null);
  }

  Widget _buildDropdownField(
      {required String label,
      required String hint,
      String? value,
      required List<String> items,
      required void Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) =>
                DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: kColorCard,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: kColorBorder))),
        validator: (value) =>
            value == null ? 'Please select an option' : null);
  }

  Widget _buildRadioGroup(
      {required String label,
      required List<String> options,
      required String groupValue,
      required void Function(String?)? onChanged}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: kColorSecondaryText,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8.0),
          Container(
              decoration: BoxDecoration(
                  color: kColorCard,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: kColorBorder)),
              child: Column(
                  children: options.map((option) {
                return RadioListTile<String>(
                    title: Text(option,
                        style: GoogleFonts.inter(fontSize: 14.0)),
                    value: option,
                    groupValue: groupValue,
                    onChanged: onChanged,
                    activeColor: kColorPrimary,
                    contentPadding: EdgeInsets.zero, 
                    dense: true,
                );
              }).toList()))
        ]);
  }

  Widget _buildChipGroup(List<String> options, List<String> selectedValues,
      Function(bool, String) onSelected) {
    return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: options.map((option) {
          final isSelected = selectedValues.contains(option);
          return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onSelected(selected, option),
              labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : kColorPrimaryText,
                  fontWeight: FontWeight.w500),
              backgroundColor: kColorCard,
              selectedColor: kColorPrimary,
              showCheckmark: false,
              shape: StadiumBorder(
                  side: BorderSide(
                      color:
                          isSelected ? kColorPrimary : kColorBorder)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 8.0));
        }).toList());
  }

  Widget _buildPieChartLegend() {
    return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Indicator(color: kChartProtein, text: 'Protein'),
          _Indicator(color: kChartCarbs, text: 'Carbs'),
          _Indicator(color: kChartFat, text: 'Fat')
        ]);
  }

  Widget _buildAnalysisItem(IconData icon, String title,
      List<String> items, Color color) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20.0),
            const SizedBox(width: 12.0),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: kColorPrimaryText))
          ]),
          const SizedBox(height: 8.0),
          ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
              child: Text('• $item',
                  style: GoogleFonts.inter(
                      fontSize: 14.0, color: kColorSecondaryText))))
        ]);
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const _Indicator({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 16,
          height: 16,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kColorSecondaryText))
    ]);
  }
}