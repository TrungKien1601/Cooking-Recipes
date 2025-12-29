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
  final Color kBgColor = const Color(0xFF151522);
  final Color kPrimaryColor = const Color(0xFF568C4C);

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
          // --- CHUYỂN SANG TRANG KẾT QUẢ ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientIdentifyScreen(
                imageFile: File(pickedFile.path),
                detectedIngredients: result['data'], // Truyền dữ liệu qua
              ),
            ),
          );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        leading: const BackButton(color: Colors.white),
        title: Text("Soi Thực Phẩm", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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