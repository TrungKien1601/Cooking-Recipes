import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; 

import 'barcode_identify_screen.dart';
import 'ingredient_scanner_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  // Cấu hình cho bản 3.5.7
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bản 3.5.7 không có controller.value.isInitialized
    // Ta chỉ cần gọi start/stop
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // --- 1. XỬ LÝ ẢNH TỪ THƯ VIỆN (Code chuẩn v3.5.7) ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Bản 3.5.7 trả về bool (Tìm thấy hay không)
      // Nếu true -> Nó sẽ tự động kích hoạt hàm onDetect ở dưới
      final bool found = await controller.analyzeImage(image.path);

      if (!found) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy mã vạch nào'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    }
  }

  // --- 2. XỬ LÝ KHI TÌM THẤY MÃ ---
  void _onCodeScanned(String code) {
    if (_isNavigating || code.isEmpty) return;

    setState(() => _isNavigating = true);
    HapticFeedback.mediumImpact();

    // Dừng camera
    controller.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeResultScreen(scannedCode: code),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isNavigating = false);
        // Delay nhẹ để tránh lag camera khi quay lại
        Future.delayed(const Duration(milliseconds: 200), () {
           controller.start();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Vùng quét
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            // Bản 3.5.7 có thể không hỗ trợ scanWindow trực tiếp trong widget này, 
            // nhưng nó vẫn quét toàn màn hình ok.
            errorBuilder: (context, error, child) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text('Lỗi Camera', style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isNavigating) {
                final String code = barcodes.first.rawValue ?? "";
                _onCodeScanned(code);
              }
            },
          ),

          // Lớp phủ tối + Khung
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow: scanWindow),
            child: Container(),
          ),

          _buildTopBar(),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              "Quét Mã Vạch",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Nút Flash đơn giản (Vì bản 3.5.7 quản lý state flash phức tạp hơn)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => controller.toggleTorch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
            stops: [0.0, 0.6],
          ),
        ),
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Đặt mã vạch vào khung hình vuông',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.image_rounded,
                  label: 'Thư viện',
                  onPressed: _pickImageFromGallery,
                ),
                _buildActionButton(
                  icon: Icons.qr_code_scanner, 
                  label: 'Mã vạch',
                  isHighlighted: true,
                  onPressed: () {}, 
                ),
                _buildActionButton(
                  icon: Icons.camera_enhance_rounded, 
                  label: 'Soi AI', 
                  onPressed: () {
                    controller.stop(); 
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IngredientScannerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed, 
    bool isHighlighted = false
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.green : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: isHighlighted ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isHighlighted ? Colors.greenAccent : Colors.white70,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontSize: 12
            ),
          )
        ],
      ),
    );
  }
}

// Class vẽ khung (ScannerOverlayPainter)
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutOutPath = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)));

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final backgroundPathComplete = Path.combine(PathOperation.difference, backgroundPath, cutOutPath);
    canvas.drawPath(backgroundPathComplete, backgroundPaint);
    
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double cornerSize = 30;
    final r = scanWindow;
    
    canvas.drawLine(r.topLeft, r.topLeft + Offset(0, cornerSize), borderPaint);
    canvas.drawLine(r.topLeft, r.topLeft + Offset(cornerSize, 0), borderPaint);
    canvas.drawLine(r.topRight, r.topRight + Offset(0, cornerSize), borderPaint);
    canvas.drawLine(r.topRight, r.topRight - Offset(cornerSize, 0), borderPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft - Offset(0, cornerSize), borderPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(cornerSize, 0), borderPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight - Offset(0, cornerSize), borderPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight - Offset(cornerSize, 0), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}