import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeService {
  // ⚠️ Đổi URL ngrok khi chạy lại
  static const String domain = "https://erythroblastotic-tonya-affrontedly.ngrok-free.dev";
  static const String baseUrl = "$domain/api/recipes"; // Đưa /recipes vào đây luôn cho gọn

  // --- HELPER: HEADERS ---
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
  // 1. LẤY DANH SÁCH (HOME, SEARCH, FILTER)
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
    String? status, 
    bool excludeAi = false,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (difficulty != null && difficulty != 'Tất cả') queryParams['difficulty'] = difficulty;
      if (authorId != null) queryParams['authorId'] = authorId;
      if (status != null) queryParams['status'] = status;
      if (excludeAi) queryParams['excludeAi'] = 'true';

      if (mealTimeTags != null && mealTimeTags.isNotEmpty) queryParams['mealTimeTags'] = mealTimeTags;
      if (dietTags != null && dietTags.isNotEmpty) queryParams['dietTags'] = dietTags;
      if (regionTags != null && regionTags.isNotEmpty) queryParams['regionTags'] = regionTags;
      if (dishtypeTags != null && dishtypeTags.isNotEmpty) queryParams['dishtypeTags'] = dishtypeTags;

      // URL: /api/recipes
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
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
  // 2. TẠO & UPDATE CÔNG THỨC (Dùng chung cho cả AI Save)
  // ============================================================

  static Future<Map<String, dynamic>> getCreateOptions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/init-create'), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi tải options"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> createRecipe(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    try {
      final headers = await _getHeaders();
      // URL: /api/recipes
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      headers.remove("Content-Type");
      request.headers.addAll(headers);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', // Backend nhận key là 'image'
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      _addFieldsToRequest(request, data);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          return json.decode(response.body);
        } catch (e) {
          return {"success": false, "message": "Lỗi server: ${response.body}"};
        }
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateRecipe(
      String id, Map<String, dynamic> data, File? imageFile) async {
    try {
      final headers = await _getHeaders();
      // URL: /api/recipes/:id
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$id'));

      headers.remove("Content-Type");
      request.headers.addAll(headers);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
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

  // ============================================================
  // 3. UPLOAD VIDEO
  // ============================================================
  static Future<String?> uploadVideo(File videoFile) async {
    try {
      final headers = await _getHeaders();
      // URL: /api/recipes/upload-video
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-video'));

      headers.remove("Content-Type");
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(
        'video', // Backend nhận key là 'video'
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
      return null;
    }
  }

  // ============================================================
  // 4. CHI TIẾT & DELETE
  // ============================================================
  static Future<Map<String, dynamic>> getRecipeDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"success": false, "message": "Không tìm thấy"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<Map<String, dynamic>> deleteRecipe(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi xóa bài"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // ============================================================
  // 5. TƯƠNG TÁC (SAVED / BOOKMARK)
  // ============================================================
  static Future<Map<String, dynamic>> toggleSave(String recipeId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/toggle-save');
      final response = await http.post(uri, headers: headers, body: jsonEncode({"recipeId": recipeId}));
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi thao tác"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<Map<String, dynamic>> getSavedRecipes({int page = 1, int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi tải danh sách"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // ============================================================
  // 6. TIỆN ÍCH AI & SEARCH
  // ============================================================

  static Future<Map<String, dynamic>> analyzeIngredients(List<Map<String, dynamic>> ingredients) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: headers,
        body: jsonEncode({"ingredients": ingredients}),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi phân tích"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<List<Map<String, dynamic>>> searchMasterIngredients(String query) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/ingredients/search').replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 7. NOTIFICATIONS
  // ============================================================
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi tải thông báo"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notifications/$notificationId/read');
      final response = await http.put(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notifications/$id');
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {"success": false, "message": "Lỗi xóa"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // ============================================================
  // 8. PRIVATE HELPERS
  // ============================================================
  static void _addFieldsToRequest(http.MultipartRequest request, Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value != null) {
        // Backend dùng parseSafeJSON nên cần encode object/list thành string
        if (value is List || value is Map) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });
  }
}