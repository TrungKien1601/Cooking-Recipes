import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scan_service.dart';
import 'ingredient_identify_screen.dart'; // Import màn hình kết quả

class IngredientScannerScreen extends StatefulWidget {
  const IngredientScannerScreen({super.key});

  @override
  State<IngredientScannerScreen> createState() => _IngredientScannerScreenState();
}

class _IngredientScannerScreenState extends State<IngredientScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  
  // Theme Colors
  final Color kBgColor = const Color(0xFF151522);
  final Color kPrimaryColor = const Color(0xFF568C4C);
  final Color kColorSecondaryText = const Color(0xFF57636C);

  // Hàm chọn ảnh và gọi API ngay lập tức
  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() => _isAnalyzing = true);

        // Gọi API
        final File imageFile = File(pickedFile.path);
        final result = await ScanService.scanImage(imageFile);

        setState(() => _isAnalyzing = false);

        if (result['success'] == true) {
          if (!mounted) return;
          
          // Chuẩn hóa dữ liệu an toàn
          final List<dynamic> rawData = result['data'] ?? [];
          final List<Map<String, dynamic>> ingredients = rawData.map((e) => Map<String, dynamic>.from(e)).toList();

          // 1. Chờ trang xác nhận trả về kết quả (true/false)
          final bool? isSaved = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientIdentifyScreen(
                imageFile: File(pickedFile.path),
                initialIngredients: ingredients, // Dùng biến đã chuẩn hóa ở trên cho gọn
              ),
            ),
          );

          // 🔥 BỔ SUNG ĐOẠN NÀY (QUAN TRỌNG NHẤT) 🔥
          // 2. Nếu trang xác nhận báo là "Đã lưu" (true)
          if (isSaved == true) {
            if (!mounted) return;
            // Đóng màn hình Scanner này lại và báo tin vui về cho Pantry
            Navigator.pop(context, true); 
          }
          
        } else {
          _showError(result['message'] ?? "Lỗi phân tích ảnh");
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showError("Lỗi: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor, // Đổi sang màu tối cho đẹp
      appBar: AppBar(
        backgroundColor: kBgColor,
        leading: const BackButton(color: Colors.white),
        title: Text("Soi Thực Phẩm AI", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: _isAnalyzing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  const SizedBox(height: 20),
                  Text("AI đang phân tích...", style: GoogleFonts.inter(color: Colors.white70)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(Icons.center_focus_weak, size: 80, color: Colors.white54),
                  ),
                  const SizedBox(height: 50),
                  _buildBigButton(Icons.camera_alt, "Chụp Ảnh Mới", kPrimaryColor, () => _pickAndAnalyze(ImageSource.camera)),
                  const SizedBox(height: 16),
                  _buildBigButton(Icons.photo_library, "Chọn Từ Thư Viện", Colors.blueGrey, () => _pickAndAnalyze(ImageSource.gallery)),
                ],
              ),
      ),
    );
  }

  Widget _buildBigButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 250, height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      ),
    );
  }
}