import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class AuthService {
  final String baseUrl = "https://kellie-unsarcastic-hoa.ngrok-free.dev/api/auth";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  );

  // --- HÀM HELPER LẤY HEADERS ---
  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    
    Map<String, String> headers = {
      "ngrok-skip-browser-warning": "true",
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  // ==========================================================
  // 1. ĐĂNG NHẬP GOOGLE
  // ==========================================================
  Future<Map<String, dynamic>> loginWithGoogle() async {
  try {
    // 1. Force logout để user luôn chọn lại tài khoản (Tốt cho UX nút Login)
    await _googleSignIn.signOut();
    
    // 2. Mở hộp thoại Google Login
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return {'success': false, 'message': 'Hủy đăng nhập'};

    // 3. Lấy Authentication data
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Lưu ý: Đôi khi idToken có thể null trên iOS nếu config chưa chuẩn, nhưng Android thì ok.
    String? idToken = googleAuth.idToken; 

    if (idToken == null) {
      return {'success': false, 'message': 'Lỗi: Không lấy được ID Token từ Google'};
    }

    print("Google ID Token: $idToken"); // Log để debug nếu cần

    // 4. Gọi API Node.js
    final response = await http.post(
      Uri.parse('$baseUrl/google-login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({ "idToken": idToken }),
    );

    print("Server Response Status: ${response.statusCode}");
    print("Server Response Body: ${response.body}");
    
    final data = jsonDecode(response.body); 

    if (response.statusCode == 200) {
      return {
        'success': true,
        'token': data['token'],
        'userId': data['userId'],
        'isSurveyDone': data['isSurveyDone'] ?? false,
        'data': data['data'] // User info
      };
    } else {
      // Trả về message lỗi từ server (cái mình đã sửa ở controller Node.js)
      return {
        'success': false, 
        'message': data['message'] ?? 'Lỗi không xác định từ Server (${response.statusCode})'
      };
    }

  } catch (error) {
    print("Error Login Google: $error");
    // Xử lý riêng lỗi FormatException (khi server trả về HTML thay vì JSON)
    if (error is FormatException) {
       return {'success': false, 'message': 'Lỗi định dạng dữ liệu từ máy chủ.'};
    }
    return {'success': false, 'message': 'Lỗi kết nối hoặc ứng dụng: $error'};
  }
}
  
  // ==========================================================
  // 2. ĐĂNG NHẬP BẰNG EMAIL VÀ MẬT KHẨU
  // ==========================================================
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'email': email, 'password': password }),
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return { 
          'success': true, 
          'token': data['token'],
          'userId': data['userId'],
          'isSurveyDone': data['isSurveyDone'] ?? false, 
          'data': data['data']
        };
      } else {
        return { 'success': false, 'message': data['message'] ?? "Đăng nhập thất bại" };
      }
    } catch (e) {
      return { 'success': false, 'message': "Lỗi kết nối Server: $e" };
    }
  }

  // ==========================================================
  // 3. gỬI MÃ OTP
  // ==========================================================
  Future<bool> sendOtp({String? email, String? phone, String type = 'register'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({ 'email': email, 'phone': phone, 'type': type }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi API Send OTP: $e");
      return false;
    }
  }
// ==========================================================
  // 4. ĐĂNG KÝ,
  // ==========================================================
  Future<Map<String, dynamic>> verifyAndRegister(String email, String password, String username, String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 'password': password, 'username': username, 'phone': phone, 'otp': otp
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'token': data['token'],
          'userId': data['userId'],
          'data': data['data']
        };
      } else {
        return { 'success': false, 'message': data['message'] ?? 'Đăng ký thất bại' };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
  // ==========================================================
  // 5.   QUÊN MẬT KHẨU
  // ==========================================================
  Future<bool> forgotPassword({String? email, String? phone}) async {
    return await sendOtp(email: email, phone: phone, type: 'forgot');
  }
  // ==========================================================
  // 5.   XÁC THỰC OTP QUÊN MẬT KHẨU
  // ==========================================================
  Future<bool> resetPasswordWithOTP(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password-otp'), 
        headers: {
           "Content-Type": "application/json",
           "ngrok-skip-browser-warning": "true", 
        },
        body: jsonEncode({ "email": email, "otp": otp, "newPassword": newPassword }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // ==========================================================
  // 6.   TÙY CHON KHẢO SÁT
  // ==========================================================
  Future<Map<String, List<String>>> getSurveyOptions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/survey-options'), 
        headers: { 'Content-Type': 'application/json', "ngrok-skip-browser-warning": "true" },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];
        return {
          'healthConditions': List<String>.from(data['healthConditions'] ?? []),
          'habits': List<String>.from(data['habits'] ?? []),
          'goals': List<String>.from(data['goals'] ?? []),
          'diets': List<String>.from(data['diets'] ?? []),
          'exclusions': List<String>.from(data['exclusions'] ?? []),
        };
      } else {
        return _getFallbackOptions();
      }
    } catch (e) {
      return _getFallbackOptions();
    }
  }
  
  Map<String, List<String>> _getFallbackOptions() {
    return {
       'healthConditions': ['Tiểu đường', 'Cao huyết áp', 'Dạ dày', 'Không có'],
       'habits': ['Ăn khuya', 'Bỏ bữa sáng', 'Ăn nhanh', 'Ăn uống điều độ'],
       'goals': ['Giảm cân', 'Tăng cân', 'Giữ dáng'],
       'diets': ['Ăn mặn (Bình thường)', 'Ăn chay (Vegetarian)', 'Keto', 'Eat Clean'], 
       'exclusions': ['Không chứa Gluten', 'Dị ứng đậu phộng', 'Dị ứng hải sản', 'Dị ứng sữa'],
    };
  }

  // ==========================================================
  // 8. GỬI KHẢO SÁT (Giữ nguyên)
  // ==========================================================
  Future<Map<String, dynamic>?> submitSurvey(String userId, Map<String, dynamic> formData) async {
    try {
      final Map<String, dynamic> bodyData = {
        'weight': formData['weight'],
        'height': formData['height'],
        'age': formData['age'],
        'gender': formData['gender'],
        'goal': formData['goal'],
        'diets': formData['diets'],
        'healthConditions': formData['healthConditions'],
        'target_weight': formData['target_weight'],
        'habits': formData['habits'],
        'food_restrictions': formData['food_restrictions'], // Bên Backend sẽ nhận là 'food_restrictions'
        'exclusions': formData['exclusions'] ?? [], 
      };

      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/submit-survey'),
        headers: headers,
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
             return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print("❌ Lỗi kết nối submitSurvey: $e");
      return null;
    }
  }

  // ==========================================================
  // 9. LẤY PROFILE (ĐÃ SỬA URL)
  // ==========================================================
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final headers = await _getHeaders();
      
      print("🚀 Đang gọi API lấy Profile...");
      print("URL: $baseUrl/get-profile");
      print("Headers: $headers"); // Kiểm tra xem có Token không?
      
      // Hiện tại code của bạn đang là:
      final uri = Uri.parse('$baseUrl/get-profile'); 

      final response = await http.get(
        uri,
        headers: headers,
      );

      print("📡 Status Code: ${response.statusCode}");
      print("📦 Response Body: ${response.body}"); // <-- ĐÂY LÀ CHÌA KHÓA DEBUG

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Kiểm tra xem backend trả về structure có đúng là ['data'] không
        if (decoded['data'] != null) {
            return decoded['data'];
        } else {
            // Trường hợp backend trả thẳng object user ở root hoặc sai key
            print("⚠️ Cảnh báo: Không tìm thấy key 'data' trong response");
            return decoded; // Thử trả về nguyên cục xem sao
        }
      } else {
        print("❌ Lỗi Server trả về: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi CRASH Code lấy profile: $e");
      return null;
    }
  }

  // ==========================================================
  // 10. CẬP NHẬT PROFILE (ĐÃ SỬA THÀNH PUT)
  // ==========================================================
  Future<bool> updateUserProfile({
    required String userId,
    String? username,
    String? phone,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? goal,
    List<String>? diets,             
    List<String>? healthConditions, 
    List<String>? habits,           
    Map<String, dynamic>? nutritionTargets,
    String? image,
  }) async {
    try {
      final Map<String, dynamic> bodyData = {
        'userId': userId,
        'username': username,
        'phone': phone,
        'gender': gender,
        'age': age,
        'height': height, // Gửi số (double), Backend tự convert -> OK
        'weight': weight, // Gửi số (double), Backend tự convert -> OK
        'goal': goal,
        'nutritionTargets': nutritionTargets,
        'image': image, 
      };
      
      if (diets != null) bodyData['diets'] = diets; 
      if (healthConditions != null) bodyData['healthConditions'] = healthConditions;
      if (habits != null) bodyData['habits'] = habits;

      final headers = await _getHeaders();

      // ✅ Sửa: Đổi thành PUT để khớp chuẩn RESTful Backend
      final response = await http.put(
        Uri.parse('$baseUrl/update-profile'), 
        headers: headers,
        body: jsonEncode(bodyData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi Update Profile: $e");
      return false;
    }
  }

  // ==========================================================
  // 11. UPLOAD AVATAR (Giữ nguyên)
  // ==========================================================
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/upload-avatar');
      var request = http.MultipartRequest('POST', uri);
      // Header multipart (có token)
      final headers = await _getHeaders(isMultipart: true);
      request.headers.addAll(headers);

      String extension = imageFile.path.split('.').last.toLowerCase();
      String subType = (extension == 'png') ? 'png' : 'jpeg';
      
      // Key 'image' khớp với Backend (upload.single('image')) -> OK
      var multipartFile = await http.MultipartFile.fromPath(
        'image', 
        imageFile.path,
        contentType: MediaType('image', subType) 
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['filePath']; // Trả về đường dẫn ảnh
        }
      }
      return null;
    } catch (e) {
      print("Lỗi kết nối upload: $e");
      return null;
    }
  }
}