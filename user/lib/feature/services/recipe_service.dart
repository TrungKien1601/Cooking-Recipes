import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Cần cho MediaType
import 'package:shared_preferences/shared_preferences.dart';

class RecipeService {
  // ✅ CẤU HÌNH DOMAIN (Thay link ngrok mới của bạn vào đây)
  static const String domain = "https://kellie-unsarcastic-hoa.ngrok-free.dev";
  static const String baseUrl = "$domain/api";

  // --- HÀM HELPER LẤY HEADERS ---
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    return {
      "Authorization": "Bearer $token",
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
    };
  }

  // ============================================================
  // 1. LẤY DANH SÁCH (HOME & FILTER)
  // ============================================================
  static Future<Map<String, dynamic>> getAllRecipes({
    int page = 1,
    int limit = 10,
    String? search,
    String? difficulty,
    String? mealTimeTags,
    String? dietTags,
    String? regionTags,
    String? dishtypeTags,
    String? authorId,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (mealTimeTags != null) queryParams['mealTimeTags'] = mealTimeTags;
      if (dietTags != null) queryParams['dietTags'] = dietTags;
      if (regionTags != null) queryParams['regionTags'] = regionTags;
      if (dishtypeTags != null) queryParams['dishtypeTags'] = dishtypeTags;
      if (authorId != null) queryParams['authorId'] = authorId;

      // Route: GET /api/recipes
      final uri = Uri.parse('$baseUrl/recipes').replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"success": false, "message": "Lỗi tải danh sách: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // ============================================================
  // 2. LẤY TAGS CHO MÀN HÌNH TẠO RECIPE
  // ============================================================
  static Future<Map<String, dynamic>> getCreateOptions() async {
    try {
      final headers = await _getHeaders();
      // Route: GET /api/recipes/init-create
      final response = await http.get(Uri.parse('$baseUrl/recipes/init-create'), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"success": false, "message": "Lỗi tải tags"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // ============================================================
  // 3. TẠO CÔNG THỨC MỚI
  // ============================================================
  static Future<Map<String, dynamic>> createRecipe(
      Map<String, dynamic> data,
      File imageFile,
  ) async {
    try {
      final headers = await _getHeaders();
      // Route: POST /api/recipes
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recipes'));
      
      headers.remove("Content-Type"); // Để Multipart tự xử lý boundary
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      _addFieldsToRequest(request, data);
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
          return json.decode(response.body);
      } else {
          try {
            return json.decode(response.body);
          } catch (e) {
            return {"success": false, "message": response.body};
          }
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // ============================================================
  // 4. UPLOAD VIDEO
  // ============================================================
  static Future<String?> uploadVideo(File videoFile) async {
    try {
      final headers = await _getHeaders();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recipes/upload-video'));
      
      headers.remove("Content-Type");
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType('video', 'mp4'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data']; 
      }
      return null;
    } catch (e) {
      print("Exception upload video: $e");
      return null;
    }
  }

  // ============================================================
  // 5. CHI TIẾT RECIPE
  // ============================================================
  static Future<Map<String, dynamic>> getRecipeDetail(String id) async {
    try {
      final headers = await _getHeaders();
      // Route: GET /api/recipes/:id
      final response = await http.get(Uri.parse('$baseUrl/recipes/$id'), headers: headers);
      
      if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded['success'] == true) return decoded;
          return {'success': true, 'data': decoded};
      }
      return {"success": false, "message": "Không tìm thấy"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // ============================================================
  // 6. CÁC HÀM KHÁC (Update, Delete, Analyze)
  // ============================================================
  
  static Future<Map<String, dynamic>> updateRecipe(String id, Map<String, dynamic> data, File? imageFile) async {
    try {
      final headers = await _getHeaders();
      // Route: PUT /api/recipes/:id
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/recipes/$id'));
      
      headers.remove("Content-Type");
      request.headers.addAll(headers);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', imageFile.path, contentType: MediaType('image', 'jpeg'),
        ));
      }
      _addFieldsToRequest(request, data);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi cập nhật"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<Map<String, dynamic>> deleteRecipe(String id) async {
    try {
      final headers = await _getHeaders();
      // Route: DELETE /api/recipes/:id
      final response = await http.delete(Uri.parse('$baseUrl/recipes/$id'), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi xóa bài"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // AI Phân tích dinh dưỡng
  static Future<Map<String, dynamic>> analyzeIngredients(List<Map<String, dynamic>> ingredients) async {
    try {
      final headers = await _getHeaders();
      // Route: POST /api/recipes/analyze
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/analyze'),
        headers: headers,
        body: jsonEncode({"ingredients": ingredients}),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi phân tích"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // Tìm kiếm nguyên liệu
  static Future<List<Map<String, dynamic>>> searchMasterIngredients(String query) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/recipes/ingredients/search').replace(queryParameters: {'q': query});
      
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
              return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print("Lỗi search ingredients: $e");
      return [];
    }
  }

  // --- HELPER: CHUYỂN DỮ LIỆU SANG STRING ---
  static void _addFieldsToRequest(http.MultipartRequest request, Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value != null) {
        if (value is List || value is Map) {
           request.fields[key] = jsonEncode(value);
        } else {
           request.fields[key] = value.toString();
        }
      }
    });
  }

  // ============================================================
  // 7. NOTIFICATIONS
  // ============================================================
  
  // Lấy danh sách thông báo
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      // Route: GET /api/recipes/notifications
      final response = await http.get(Uri.parse('$baseUrl/recipes/notifications'), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"success": false, "message": "Lỗi tải thông báo"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Đánh dấu đã đọc
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      // Route: PUT /api/recipes/notifications/:id/read
      final uri = Uri.parse('$baseUrl/recipes/notifications/$notificationId/read');
      final response = await http.put(uri, headers: headers);

      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  // Xóa thông báo
  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      final headers = await _getHeaders();
      // Route: DELETE /api/recipes/notifications/:id
      final uri = Uri.parse('$baseUrl/recipes/notifications/$id');
      
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body); 
      } else {
        return {"success": false, "message": "Lỗi xóa: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // ============================================================
  // 8. FAVORITES (API - ĐÃ SỬA LẠI ĐỂ KHỚP BACKEND)
  // ============================================================

  static Future<bool> toggleFavorite(String recipeId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/recipes/toggle-like');
      
      final response = await http.post(
        uri, 
        headers: headers,
        body: jsonEncode({"recipeId": recipeId}) // Body phải có recipeId
      );

      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         return data['isFavorite'] ?? false; // Backend trả về isFavorite: true/false
      }
      return false;
    } catch (e) {
      print("Lỗi toggle like: $e");
      return false;
    }
  }

  // ✅ API Get Favorites: Lấy danh sách từ server (Không dùng Local Storage nữa)
  static Future<Map<String, dynamic>> getFavoriteRecipes() async {
    try {
      final headers = await _getHeaders();
      // Route: GET /api/recipes/favorites
      final response = await http.get(Uri.parse('$baseUrl/recipes/favorites'), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body); // {success: true, data: [...]}
      } else {
        return {"success": false, "message": "Lỗi tải yêu thích: ${response.statusCode}"};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}