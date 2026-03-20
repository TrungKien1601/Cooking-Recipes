import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Cần cho upload ảnh

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ⚠️ QUAN TRỌNG: Kiểm tra lại server.js xem bạn mount route là gì?
  // Nếu server.js: app.use('/api/users', userRoute) -> thì url là .../api/users
  final String baseUrl = "https://erythroblastotic-tonya-affrontedly.ngrok-free.dev/api/auth";

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // --- HELPER: LẤY TOKEN ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- HELPER: LƯU SESSION ---
  Future<void> _saveSession(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    print("✅ Session Saved: $userId");
  }

  // --- HELPER: CLEAR SESSION (LOGOUT) ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Google SignOut Error (Ignored): $e");
    }
    print("👋 Logged out");
  }

  // 🔥 CORE: HÀM GỌI API CHUNG
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      // 1. Chuẩn bị Headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        "ngrok-skip-browser-warning": "true", // Chống màn hình warning của Ngrok
      };

      // 2. Tự động gắn Token
      if (requiresAuth) {
        final token = await _getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        } else {
          // Nếu yêu cầu Auth mà không có Token -> Logout luôn
          return {'success': false, 'message': 'Bạn chưa đăng nhập'};
        }
      }

      // 3. Gọi API
      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
      } else {
        response = await http.get(uri, headers: headers);
      }

      final data = jsonDecode(response.body);

      // 4. Xử lý kết quả chung
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data}; // Merge data server trả về vào
      } else if (response.statusCode == 401) {
        // Token hết hạn hoặc không hợp lệ
        await logout();
        return {'success': false, 'message': 'Phiên đăng nhập hết hạn'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Lỗi server'};
      }
    } catch (e) {
      print("❌ API Error [$endpoint]: $e");
      return {'success': false, 'message': 'Lỗi kết nối server'};
    }
  }

  // ==========================================================
  // 1. AUTHENTICATION
  // ==========================================================

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Đảm bảo chọn tài khoản mới
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Hủy đăng nhập'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) return {'success': false, 'message': 'Lỗi ID Token Google'};

      // Backend route: POST /google-login
      final result = await _request('POST', '/google-login', body: {"idToken": googleAuth.idToken});

      if (result['success']) {
        // Lưu ý: Backend trả về user._id nằm trong object data hoặc trực tiếp
        String uId = result['userId'] ?? result['data']['_id'];
        await _saveSession(result['token'], uId);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Google Auth Error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    // Backend route: POST /login
    final result = await _request('POST', '/login', body: {'email': email, 'password': password});
    if (result['success']) {
      String uId = result['userId'] ?? result['data']['_id'];
      await _saveSession(result['token'], uId);
    }
    return result;
  }

  Future<Map<String, dynamic>> verifyAndRegister(Map<String, dynamic> data) async {
    // Backend route: POST /register
    final result = await _request('POST', '/register', body: data);
    if (result['success']) {
      String uId = result['userId'] ?? result['data']['_id'];
      await _saveSession(result['token'], uId);
    }
    return result;
  }

  // ==========================================================
  // 2. OTP & PASSWORD
  // ==========================================================

  Future<bool> sendOtp({String? email, String type = 'register'}) async {
    final result = await _request('POST', '/send-otp', body: {'email': email, 'type': type});
    return result['success'];
  }

  Future<bool> resetPasswordWithOTP(String email, String otp, String newPassword) async {
    final result = await _request('POST', '/reset-password', body: {
      "email": email, "otp": otp, "newPassword": newPassword
    });
    return result['success'];
  }

  // ==========================================================
  // 3. USER DATA & PROFILE
  // ==========================================================

  Future<Map<String, dynamic>?> getUserProfile() async {
    // Backend route: GET /profile
    final result = await _request('GET', '/profile', requiresAuth: true);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> updateData) async {
    // Backend route: PUT /profile
    final result = await _request('PUT', '/profile', body: updateData, requiresAuth: true);
    return result['success'];
  }

  // Upload Avatar dùng MultipartRequest riêng
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      // Backend route: POST /avatar
      var uri = Uri.parse('$baseUrl/avatar');
      var request = http.MultipartRequest('POST', uri);

      final token = await _getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      String extension = imageFile.path.split('.').last.toLowerCase();
      String subType = (extension == 'jpg' || extension == 'jpeg') ? 'jpeg' : 'png';
      
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', subType),
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Backend trả về: { success: true, filePath: "..." } hoặc user object
        return data['filePath'] ?? data['data']['image'];
      }
      return null;
    } catch (e) {
      print("Upload Avatar Error: $e");
      return null;
    }
  }

  // ==========================================================
  // 4. FEATURES (SURVEY & MEAL)
  // ==========================================================

  Future<Map<String, List<String>>> getSurveyOptions() async {
    // Backend route: GET /survey-options
    final result = await _request('GET', '/survey-options', requiresAuth: true); // Nên để auth
    
    if (result['success'] && result['data'] != null) {
      final data = result['data'];
      return {
        'healthConditions': List<String>.from(data['healthConditions'] ?? []),
        'habits': List<String>.from(data['habits'] ?? []),
        'goals': List<String>.from(data['goals'] ?? []),
        'diets': List<String>.from(data['diets'] ?? []),
        'exclusions': List<String>.from(data['exclusions'] ?? []),
      };
    }
    return _getFallbackOptions();
  }

  // Hàm này giờ trả về cả Nutrition + Filtered Recipes
  Future<Map<String, dynamic>?> submitSurvey(Map<String, dynamic> formData) async {
    // Backend route: POST /survey
    final result = await _request('POST', '/survey', body: formData, requiresAuth: true);
    
    // Result data bao gồm: { nutrition, recommendations, filteredRecipes, ... }
    return result['success'] ? result['data'] : null;
  }
  
  Future<Map<String, dynamic>?> getMealSuggestions() async {
    // Backend route: GET /meal-suggestions
    final result = await _request('GET', '/meal-suggestions', requiresAuth: true);
    return result['success'] ? result['data'] : null;
  }

  // Fallback data khi server lỗi hoặc mất mạng
  Map<String, List<String>> _getFallbackOptions() {
    return {
      'healthConditions': ['Tiểu đường', 'Cao huyết áp', 'Dạ dày', 'Không có'],
      'habits': ['Ăn khuya', 'Bỏ bữa sáng', 'Ăn nhanh', 'Ăn uống điều độ'],
      'goals': ['Giảm cân', 'Tăng cân', 'Giữ dáng', 'Tăng cơ'],
      'diets': ['Ăn mặn (Bình thường)', 'Ăn chay (Vegetarian)', 'Keto', 'Eat Clean'],
      'exclusions': ['Hải sản', 'Đậu phộng', 'Sữa', 'Gluten', 'Trứng'],
    };
  }
}