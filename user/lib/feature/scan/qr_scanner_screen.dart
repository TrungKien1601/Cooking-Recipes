import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Để dùng HapticFeedback

import 'barcode_identify_screen.dart';
import 'ingredient_scanner_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

// Thêm WidgetsBindingObserver để xử lý khi app ẩn/hiện
class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    // Tắt các format không cần thiết để quét nhanh hơn
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe sự thay đổi trạng thái App (Foreground/Background)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // --- SỬA CHO BẢN CŨ: Dùng isStarting thay vì value.isInitialized ---
    if (!controller.isStarting) return;
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        controller.start(); 
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // --- 1. XỬ LÝ ẢNH TỪ THƯ VIỆN (SỬA LẠI CHO BẢN CŨ) ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // --- SỬA: analyzeImage bản cũ trả về bool ---
      // Nếu true => Thư viện tự động gọi onDetect, không cần làm gì thêm ở đây
      final bool found = await controller.analyzeImage(image.path);

      if (!found) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy mã vạch hợp lệ trong ảnh!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    }
  }

  // --- 2. XỬ LÝ KHI TÌM THẤY MÃ ---
  void _onCodeScanned(String code) {
    if (_isNavigating || code.isEmpty) return;

    setState(() {
      _isNavigating = true;
    });

    // Rung nhẹ xác nhận đã quét
    HapticFeedback.lightImpact();

    // Dừng camera
    controller.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeResultScreen(scannedCode: code),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        controller.start(); // Start lại camera khi quay về
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán vùng quét ở giữa màn hình
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Lớp 1: Camera View
          MobileScanner(
            controller: controller,
            // --- BỎ scanWindow NẾU BẢN CŨ QUÁ CŨ KHÔNG HỖ TRỢ, NHƯNG THƯỜNG VẪN CÓ ---
            scanWindow: scanWindow, 
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Vui lòng cấp quyền Camera',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
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

          // Lớp 2: Overlay tối xung quanh + Khung
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow: scanWindow),
            child: Container(),
          ),

          // Lớp 3: Top Bar
          _buildTopBar(),

          // Lớp 4: Bottom Bar
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
            
            // --- SỬA: Dùng IconButton thường thay vì ValueListenableBuilder (tránh lỗi torchState) ---
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
        height: 180.0, 
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Di chuyển mã vạch vào khung',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.image_rounded,
                  label: 'Thư viện',
                  onPressed: _pickImageFromGallery,
                ),
                _buildActionButton(
                  icon: Icons.local_grocery_store_rounded, 
                  label: 'Soi thực phẩm',
                  isHighlighted: true,
                  onPressed: () {
                    controller.stop(); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IngredientScannerScreen(),
                      ),
                    ).then((_) {
                      if(mounted) controller.start();
                    });
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
              color: isHighlighted ? Colors.green : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isHighlighted ? Colors.greenAccent : Colors.white,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontSize: 12
            ),
          )
        ],
      ),
    );
  }
}

// --- Class vẽ khung overlay (Giữ nguyên vì không ảnh hưởng version) ---
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)));

    final backgroundPathComplete = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutOutPath,
    );
    
    canvas.drawPath(backgroundPathComplete, Paint()..color = Colors.black.withOpacity(0.6));
    
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)), 
        borderPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}