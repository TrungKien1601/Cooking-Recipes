import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart'; 

class ScanService {

  // --- CẤU HÌNH BASE URL ---
  static String get baseUrl {
    if (dotenv.env['BASE_URL'] != null && dotenv.env['BASE_URL']!.isNotEmpty) {
      return dotenv.env['BASE_URL']!;
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api";
    }
    return "http://localhost:3000/api";
  }

  // --- HELPER HEADERS ---
  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "ngrok-skip-browser-warning": "true", 
    };

    if (!isMultipart) {
      headers["Content-Type"] = "application/json";
    }
    return headers;
  }

  // --- HELPER ERROR ---
  static Map<String, dynamic> _handleError(http.Response response) {
    try {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return {
        "success": false, 
        "message": decoded['message'] ?? "Lỗi server: ${response.statusCode}",
        "data": null
      };
    } catch (e) {
      print("❌ Error Parse Body (${response.statusCode}): ${response.body}");
      return {
        "success": false, 
        "message": "Lỗi kết nối hoặc server bảo trì (${response.statusCode})"
      };
    }
  }

  static MediaType _getMediaType(String path) {
    final mimeType = lookupMimeType(path); 
    if (mimeType != null) {
      final split = mimeType.split('/');
      return MediaType(split[0], split[1]);
    }
    return MediaType('image', 'jpeg'); 
  }

  // ============================================================
  // 1. CÁC API SCAN (Đã fix Token cho scanImage)
  // ============================================================

  static Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    final url = Uri.parse('$baseUrl/scan/barcode');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({"barcode": barcode.trim()}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return json.decode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> scanImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/scan/image');
    try {
      final headers = await _getHeaders(isMultipart: true);
      
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers); // Add token vào request

      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imageFile.path,
        contentType: _getMediaType(imageFile.path), 
      ));
      var streamedResponse = await request.send().timeout(const Duration(seconds: 180)); 
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return json.decode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi xử lý ảnh: $e"};
    }
  }

  // ============================================================
  // 2. CÁC API PANTRY & UPLOAD
  // ============================================================
  
  static Future<Map<String, dynamic>> uploadFoodImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/scan/upload-food');
    try {
      final headers = await _getHeaders(isMultipart: true);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      request.files.add(await http.MultipartFile.fromPath(
        'image', imageFile.path, contentType: _getMediaType(imageFile.path),
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return jsonDecode(response.body); 
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi upload: $e"};
    }
  }

  static Future<Map<String, dynamic>> uploadMultipleImages(List<File> images) async {
    final url = Uri.parse('$baseUrl/scan/upload-multiple-foods');
    try {
      final headers = await _getHeaders(isMultipart: true);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      for (var file in images) {
        request.files.add(await http.MultipartFile.fromPath(
          'images', file.path, contentType: _getMediaType(file.path),
        ));
      }

      var streamedResponse = await request.send().timeout(const Duration(minutes: 3));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return jsonDecode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi upload nhiều ảnh: $e"};
    }
  }

  static Future<Map<String, dynamic>> addToPantry(Map<String, dynamic> itemData) async {
    final url = Uri.parse('$baseUrl/pantry'); 
    try {
      final headers = await _getHeaders(); 
      final response = await http.post(
        url, headers: headers, body: jsonEncode(itemData),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
      } 
      // Thêm xử lý lỗi validation cụ thể từ backend
      else if (response.statusCode == 400) {
          final decoded = json.decode(response.body);
          return {"success": false, "message": decoded['message'] ?? "Dữ liệu không hợp lệ"};
      }
      else if (response.statusCode == 401) {
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
      
      if (response.statusCode == 200) return json.decode(response.body);
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
        url, headers: headers, body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) return json.decode(response.body);
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
      
      if (response.statusCode == 200) return json.decode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng"};
    }
  }

  // ============================================================
  // 3. API GỢI Ý & LỊCH SỬ (Đã tối ưu Time-out)
  // ============================================================

  static Future<Map<String, dynamic>> suggestRecipes(List<String> ingredients, {String? context}) async {
    // ⚠️ CHECK ROUTE: Backend phải có route POST /api/scan/suggest-guest
    final url = Uri.parse('$baseUrl/scan/suggest-guest'); 
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ingredients": ingredients,
          "context": context ?? "" 
        }),
      ).timeout(const Duration(seconds: 240)); 
      
      if (response.statusCode == 200) return json.decode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "AI đang bận, thử lại sau nhé"};
    }
  }
  
  // Gợi ý cho User (Có Token)
  static Future<Map<String, dynamic>> suggestChefRecipes(List<String>? specificIngredients, {String? context}) async {
    final url = Uri.parse('$baseUrl/pantry/suggest-chef');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
            "ingredients": specificIngredients ?? [],
            "context": context ?? "" 
        }), 
      ).timeout(const Duration(seconds: 240)); 
      
      if (response.statusCode == 200) return json.decode(response.body);
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

      if (response.statusCode == 200) return json.decode(response.body);
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
      
      if (response.statusCode == 200) return json.decode(response.body);
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

      if (response.statusCode == 200) return json.decode(response.body);
      return _handleError(response);
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }
}