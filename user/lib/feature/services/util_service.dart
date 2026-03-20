import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UtilService {
  // ⚠️ LƯU Ý: Đảm bảo domain này GIỐNG HỆT bên RecipeService
  static const String domain = "https://erythroblastotic-tonya-affrontedly.ngrok-free.dev";
  static const String baseUrl = "$domain/api";

  // --- Helper lấy Headers (giống các service khác) ---
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
  // TÌM ẢNH (Gọi qua Backend để giấu API Key)
  // ============================================================
  static Future<String?> searchImage(String query) async {
    try {
      final headers = await _getHeaders();
      
      // Gọi API: GET /api/utils/search-image?query=...
      final uri = Uri.parse('$baseUrl/utils/search-image').replace(queryParameters: {
        'query': query,
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']; // Trả về URL ảnh
        }
      }
      return null;
    } catch (e) {
      print("UtilService Error: $e");
      return null;
    }
  }
}