import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class ScanService {
  // ⚠️ LƯU Ý: Đổi URL này mỗi khi ngrok khởi động lại
  // Nếu chạy máy ảo Android: dùng 10.0.2.2 thay vì localhost
  static const String baseUrl = "https://kellie-unsarcastic-hoa.ngrok-free.dev/api"; 

  // --- HÀM HELPER LẤY HEADERS ---
  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "ngrok-skip-browser-warning": "true", // Bypass warning của Ngrok miễn phí
    };

    if (!isMultipart) {
      headers["Content-Type"] = "application/json";
    }
    return headers;
  }

  // --- HELPER XỬ LÝ LỖI CHUNG ---
  static Map<String, dynamic> _handleError(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      return {
        "success": false, 
        "message": decoded['message'] ?? "Lỗi server: ${response.statusCode}",
        "data": null
      };
    } catch (e) {
      print("❌ Error Parse Body (${response.statusCode}): ${response.body}");
      return {
        "success": false, 
        "message": "Máy chủ đang bảo trì hoặc lỗi kết nối (${response.statusCode})"
      };
    }
  }

  // ============================================================
  // 1. CÁC API SCAN & NHẬN DIỆN
  // ============================================================

  static Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    final url = Uri.parse('$baseUrl/scan/barcode');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({"barcode": barcode}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> scanImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/scan/image');
    try {
      var request = http.MultipartRequest('POST', url);
      // API Scan Image là Public, không cần token
      
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), 
      ));

      // AI xử lý ảnh có thể lâu, tăng timeout lên 120s
      var streamedResponse = await request.send().timeout(const Duration(seconds: 120)); 
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi xử lý ảnh: $e"};
    }
  }

  // ============================================================
  // 2. CÁC API PANTRY (TỦ LẠNH) & UPLOAD
  // ============================================================

  // Upload 1 ảnh món ăn (để lưu vào DB)
  static Future<Map<String, dynamic>> uploadFoodImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/scan/upload-food');
    try {
      final headers = await _getHeaders(isMultipart: true);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imageFile.path, 
        contentType: MediaType('image', 'jpeg'),
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // {success: true, filePath: "uploads/..."}
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi upload: $e"};
    }
  }

  // Upload nhiều ảnh
  static Future<Map<String, dynamic>> uploadMultipleImages(List<File> images) async {
    final url = Uri.parse('$baseUrl/scan/upload-multiple-foods');
    try {
      final headers = await _getHeaders(isMultipart: true);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      for (var file in images) {
        request.files.add(await http.MultipartFile.fromPath(
          'images', // Key này phải khớp với upload.array('images') ở backend
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      var streamedResponse = await request.send().timeout(const Duration(minutes: 3));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi upload nhiều ảnh: $e"};
    }
  }

  // Thêm vào tủ lạnh
  static Future<Map<String, dynamic>> addToPantry(Map<String, dynamic> itemData) async {
    final url = Uri.parse('$baseUrl/pantry'); 
    try {
      final headers = await _getHeaders(); 
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(itemData),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
      } else if (response.statusCode == 401) {
          return {"success": false, "message": "Phiên đăng nhập hết hạn"};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {"success": false, "message": "Không thể kết nối Server"};
    }
  }

  static Future<Map<String, dynamic>> getPantry() async {
    final url = Uri.parse('$baseUrl/pantry');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng hoặc server offline"};
    }
  }

  static Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/pantry/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng"};
    }
  }

  static Future<Map<String, dynamic>> deleteItem(String id) async {
    final url = Uri.parse('$baseUrl/pantry/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng"};
    }
  }

  // ============================================================
  // 3. API GỢI Ý MÓN ĂN & LỊCH SỬ
  // ============================================================

  // Gợi ý cho khách vãng lai (hoặc user nhập tay)
  static Future<Map<String, dynamic>> suggestRecipes(List<String> ingredients) async {
    final url = Uri.parse('$baseUrl/scan/suggest-guest'); 
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"ingredients": ingredients}),
      ).timeout(const Duration(seconds: 180)); // Tăng timeout cho AI
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "AI đang bận, thử lại sau nhé"};
    }
  }
  
  // Gợi ý dựa trên tủ lạnh (Cần login)
  static Future<Map<String, dynamic>> suggestChefRecipes(List<String>? specificIngredients) async {
    final url = Uri.parse('$baseUrl/pantry/suggest-chef');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"ingredients": specificIngredients ?? []}), 
      ).timeout(const Duration(seconds: 180)); // Tăng timeout cho AI
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Kết nối thất bại hoặc AI quá tải"};
    }
  }

  static Future<Map<String, dynamic>> getRecipeHistory() async {
    final url = Uri.parse('$baseUrl/pantry/history');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }

  static Future<Map<String, dynamic>> clearRecipeHistory() async {
    final url = Uri.parse('$baseUrl/pantry/history');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body); 
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  static Future<Map<String, dynamic>> deleteHistoryItems(List<String> ids) async {
    final url = Uri.parse('$baseUrl/pantry/history/delete');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"ids": ids}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }
}