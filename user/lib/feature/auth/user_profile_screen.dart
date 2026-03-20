import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryBackground = Color(0xFFE3ECE1);
const Color kPrimaryColor = Color(0xFF568C4C);
const Color kSecondaryBackground = Colors.white;
const Color kPrimaryText = Color(0xFF15161E);
const Color kSecondaryText = Color(0xFF57636C);
const Color kErrorColor = Color(0xFFFF5963);
const Color kAlternateBorder = Color(0xFFE0E3E7);

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Singleton instance
  final _authService = AuthService(); 

  // Controllers
  late TextEditingController _phoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _nameController; // Thêm controller cho tên nếu muốn sửa tên

  String? _selectedGoal;
  bool _isLoading = true;
  bool _isDataChanged = false;

  // Image Picking
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _goalOptions = [
    "Giảm cân", "Tăng cơ", "Tăng cân lành mạnh", "Duy trì vóc dáng",
    "Cải thiện tiêu hóa", "Tăng cường hệ miễn dịch", "Đẹp da & Chống lão hóa",
    "Tăng cường năng lượng", "Cải thiện giấc ngủ", "Thanh lọc cơ thể (Detox)"
  ];

  Map<String, dynamic> _userData = {
    'uid': '', 'email': '', 'username': '', 'image': '',
    'phone': '', 'gender': '', 'age': '',
    'height': '', 'weight': '', 'goal': null,
    'healthConditions': '', 'diets': '', 'habits': '',
    'exclusions': '', 'nutritionTargets': null,
    'ai_recommendations': '',
    'ai_foods_to_avoid': '',
  };

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _nameController = TextEditingController();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // --- HELPER: LIST TO STRING ---
  String _listToString(dynamic list) {
    if (list is List) {
      if (list.isEmpty) return '';
      bool isLongText = list.any((e) => e.toString().length > 25);
      if (isLongText) return list.map((e) => "• $e").join('\n');
      return list.join(', ');
    }
    return list?.toString() ?? '';
  }

  // --- LOGIC: FETCH DATA (Đã sửa khớp AuthService mới) ---
  Future<void> _fetchUserProfile() async {
    // 1. Load Cache trước cho mượt
    await _loadFromCache();

    // 2. Gọi API (Không cần truyền email nữa)
    final profileData = await _authService.getUserProfile();

    if (mounted) {
      if (profileData != null) {
        _populateDataToUI(profileData);
        _saveToLocalCache(profileData);
      } else {
        // Nếu API lỗi, giữ nguyên data từ cache hoặc báo lỗi
        print("⚠️ Không lấy được dữ liệu profile từ Server");
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('user_data');
    if (cachedData != null) {
      try {
        _populateDataToUI(jsonDecode(cachedData));
      } catch (e) {
        print("Lỗi parse cache: $e");
      }
    }
  }

  Future<void> _saveToLocalCache(Map<String, dynamic> newData) async {
    final prefs = await SharedPreferences.getInstance();
    String? currentCache = prefs.getString('user_data');
    Map<String, dynamic> mergedData = {};
    if (currentCache != null) mergedData = jsonDecode(currentCache);
    mergedData.addAll(newData);
    await prefs.setString('user_data', jsonEncode(mergedData));
  }

  void _populateDataToUI(Map<String, dynamic> data) {
    try {
      setState(() {
        _userData = {
          'uid': data['uid'] ?? data['_id'] ?? 'N/A',
          'email': data['email'] ?? '',
          'username': data['username'] ?? '',
          'image': data['image'] ?? '',
          'phone': data['phone'] ?? '',
          'gender': data['gender'] ?? '',
          'age': data['age']?.toString() ?? '',

          'height': (data['height'] is Map)
              ? (data['height']['value']?.toString() ?? '')
              : (data['height']?.toString() ?? ''),

          'weight': (data['weight'] is Map)
              ? (data['weight']['value']?.toString() ?? '')
              : (data['weight']?.toString() ?? ''),

          'healthConditions': _listToString(data['healthConditions']),
          'exclusions': (data['exclusions'] is List)
              ? (data['exclusions'] as List).join(', ')
              : _listToString(data['allergies']),

          'goal': data['goal'],
          'diets': data['diets'] ?? data['dietPreference'] ?? '',
          'habits': data['habits'] ?? [],
          'nutritionTargets': data['nutritionTargets'],
          'ai_recommendations': _listToString(data['ai_recommendations']),
          'ai_foods_to_avoid': _listToString(data['ai_foods_to_avoid']),
        };

        _phoneController.text = _userData['phone'];
        _heightController.text = _userData['height'];
        _weightController.text = _userData['weight'];
        _nameController.text = _userData['username'];

        String? serverGoal = _userData['goal'];
        if (serverGoal != null && serverGoal.isNotEmpty) {
          if (!_goalOptions.contains(serverGoal)) _goalOptions.add(serverGoal);
          _selectedGoal = serverGoal;
        }

        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi Crash khi map dữ liệu lên UI: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: IMAGE URL ---
  String _getProfileImageUrl() {
    String? serverImage = _userData['image'];
    if (serverImage == null || serverImage.isEmpty || serverImage.contains('default')) return '';
    if (serverImage.startsWith('http')) return serverImage;

    // Sử dụng baseUrl từ AuthService để đồng bộ
    String baseUrl = _authService.baseUrl; 
    String path = serverImage.startsWith('/') ? serverImage.substring(1) : serverImage;
    return "$baseUrl/$path?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: kPrimaryColor),
                title: const Text('Chọn từ thư viện'),
                onTap: () { _pickAndUploadImage(ImageSource.gallery); Navigator.of(context).pop(); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
                title: const Text('Chụp ảnh mới'),
                onTap: () { _pickAndUploadImage(ImageSource.camera); Navigator.of(context).pop(); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile == null) return;

      File file = File(pickedFile.path);
      setState(() {
        _imageFile = file;
        _isLoading = true;
      });

      // 1. Upload ảnh trước
      String? serverPath = await _authService.uploadAvatar(file);

      if (!mounted) return;

      if (serverPath != null) {
        // 2. Cập nhật URL ảnh vào profile (Backend có thể đã tự update, nhưng gọi PUT để chắc chắn đồng bộ các trường khác)
        // SỬA: Truyền Map thay vì named arguments
        bool success = await _authService.updateUserProfile({
          'image': serverPath,
          // Gửi các trường khác để tránh bị ghi đè null nếu backend xử lý không kỹ
          'username': _userData['username'], 
        });

        if (success) {
          setState(() {
            _userData['image'] = serverPath;
            _isLoading = false;
            _isDataChanged = true;
          });
          _saveToLocalCache({'image': serverPath});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ảnh thành công!'), backgroundColor: kPrimaryColor));
        } else {
          setState(() => _isLoading = false);
          _showError('Lỗi cập nhật data sau khi upload ảnh.');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Lỗi upload ảnh.');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi ảnh: $e");
    }
  }

  // --- LOGIC: SAVE DATA (Đã sửa khớp AuthService mới) ---
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    try {
      double? heightVal = double.tryParse(_heightController.text);
      double? weightVal = double.tryParse(_weightController.text);
      int? ageVal = int.tryParse(_userData['age'].toString());

      // SỬA: Gọi AuthService với Map<String, dynamic>
      // Không cần truyền userId vì Token đã chứa nó
      bool success = await _authService.updateUserProfile({
        'username': _userData['username'], // Nếu có cho sửa tên
        'phone': _phoneController.text.trim(),
        'height': heightVal,
        'weight': weightVal,
        'goal': _selectedGoal,
        'gender': _userData['gender'],
        'age': ageVal,
        'image': _userData['image'],
        // Các trường AI giữ nguyên
        'nutritionTargets': _userData['nutritionTargets'],
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() => _isDataChanged = true);
        await _saveToLocalCache({
          'phone': _phoneController.text.trim(),
          'height': heightVal,
          'weight': weightVal,
          'goal': _selectedGoal,
          'image': _userData['image']
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi!'), backgroundColor: kPrimaryColor));
      } else {
        _showError('Lỗi cập nhật hồ sơ (Server).');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Lỗi kết nối: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: kErrorColor));
  }

  // --- UI PART (Giữ nguyên logic UI, chỉ format lại chút) ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_isDataChanged);
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: kPrimaryBackground,
          appBar: _buildAppBar(),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: _buildBody(),
                  ),
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(_isDataChanged),
      ),
      title: Text('Thông tin cá nhân', style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4),
            child: Text('Thông tin cá nhân', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.w600, color: kSecondaryText)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: kSecondaryBackground, borderRadius: BorderRadius.circular(16)),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // _buildReadOnlyItem(icon: Icons.perm_identity, label: "UID", value: _userData['uid']), // Tắt UID đi cho gọn
                // _buildDivider(),
                _buildReadOnlyItem(icon: Icons.person_outline, label: "Tên người dùng", value: _userData['username']),
                _buildDivider(),
                _buildReadOnlyItem(icon: Icons.email_outlined, label: "Email", value: _userData['email']),
                _buildDivider(),
                _buildTextField(controller: _phoneController, label: "Số điện thoại", icon: Icons.phone_outlined, isNumber: true),
                _buildDivider(),
                _buildTextField(controller: _heightController, label: "Chiều cao (cm)", icon: Icons.height, isNumber: true, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                _buildDivider(),
                _buildTextField(controller: _weightController, label: "Cân nặng (kg)", icon: Icons.monitor_weight_outlined, isNumber: true, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                _buildDivider(),
                _buildDropdown(label: "Mục tiêu", icon: Icons.flag_outlined, value: _selectedGoal, items: _goalOptions, onChanged: (v) => setState(() => _selectedGoal = v)),
                _buildDivider(),
                _buildReadOnlyItem(icon: Icons.wc, label: "Giới tính", value: _userData['gender']),
                _buildDivider(),
                _buildReadOnlyItem(icon: Icons.cake_outlined, label: "Tuổi", value: _userData['age']),
                
                if (_userData['healthConditions'].isNotEmpty) ...[
                  _buildDivider(), _buildReadOnlyItem(icon: Icons.health_and_safety_outlined, label: "Tình trạng sức khỏe", value: _userData['healthConditions']),
                ],
                if (_userData['exclusions'].isNotEmpty) ...[
                   _buildDivider(), _buildReadOnlyItem(icon: Icons.no_food_outlined, label: "Dị ứng / Kiêng", value: _userData['exclusions']),
                ],
                 if (_userData['ai_recommendations'].isNotEmpty) ...[
                   _buildDivider(), _buildReadOnlyItem(icon: Icons.tips_and_updates_outlined, label: "Lời khuyên từ AI", value: _userData['ai_recommendations']),
                ],

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _saveProfileChanges,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Text('Lưu thay đổi', style: GoogleFonts.interTight(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SMALL WIDGETS ---
  Widget _buildAvatarSection() {
    final imgUrl = _getProfileImageUrl();
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : (imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _defaultAvatar(), loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        })
                      : _defaultAvatar()),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 36, width: 36,
                decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Container(color: Colors.grey[200], child: Icon(Icons.person, size: 60, color: Colors.grey[400]));
  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16, color: kAlternateBorder);

  Widget _buildReadOnlyItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: kSecondaryText)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'N/A' : value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryText, height: 1.4)),
        ]))
      ]),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: kPrimaryText),
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.inter(color: kSecondaryText), prefixIcon: Icon(icon, color: kPrimaryColor), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }

  Widget _buildDropdown({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    String? validVal = (value != null && items.contains(value)) ? value : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: validVal,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontWeight: FontWeight.w500)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: kPrimaryColor), border: InputBorder.none),
      ),
    );
  }
}