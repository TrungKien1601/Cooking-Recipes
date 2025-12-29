import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart'; 

import '../services/recipe_service.dart';
import 'markdown_recipe_screen.dart'; // Đã sửa tên import cho khớp với file bookmark

// --- MÀU SẮC ---
const Color kColorBackground = Color(0xFFF1F4F8);
const Color kColorCard = Color(0xFFFFFFFF);
const Color kColorPrimary = Color(0xFF568C4C);
const Color kColorSecondaryText = Color(0xFF57636C);
const Color kColorPrimaryText = Color(0xFF15161E);
const Color kColorAlternate = Color(0xFFE0E3E7);
const Color kChartFat = Color(0xFFFBC02D);
const Color kChartCarbs = Color(0xFF0288D1);
const Color kColorProtein = Color(0xFFE64A19);

class BlogScreen extends StatefulWidget {
  final dynamic recipeData;
  final bool isOwner;

  const BlogScreen({
    super.key,
    required this.recipeData,
    this.isOwner = false,
  });

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  // ✅ Biến trạng thái yêu thích
  bool _isFavorited = false;

  String _name = '';
  String _time = '';
  String _calories = '';
  String _servings = '';
  String _description = '';
  String? _passedImageUrl;

  Map<String, dynamic> _nutritionData = {};
  List<Map<String, String>> _ingredients = [];
  List<String> _instructions = [];

  String _difficulty = 'Dễ';
  String? _chefTips;

  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  bool _hasYoutubeVideo = false;
  bool _hasUploadedVideo = false;
  String? _uploadedVideoUrl;

  @override
  void initState() {
    super.initState();
    _parseData();
    
    // ✅ FIX: Lấy trạng thái Like trực tiếp từ dữ liệu truyền vào
    // Backend đã trả về field 'isFavorite' (true/false) trong API list
    if (widget.recipeData != null) {
      _isFavorited = widget.recipeData['isFavorite'] ?? false;
    }
  }

  // ❌ ĐÃ XÓA hàm _checkFavoriteStatus vì không còn hàm RecipeService.isFavorite()

  // ✅ Hàm xử lý bấm nút Like (Gọi API)
  Future<void> _toggleFavorite() async {
    final String? id = widget.recipeData['_id'] ?? widget.recipeData['id'];
    if (id == null) return;

    // Optimistic UI: Đổi màu ngay lập tức cho mượt
    setState(() {
      _isFavorited = !_isFavorited;
    });

    try {
      // Gọi service lưu vào Server
      bool apiResult = await RecipeService.toggleFavorite(id);
      
      // Đồng bộ lại state chuẩn từ server trả về (để chắc chắn)
      if (mounted) {
        setState(() {
          _isFavorited = apiResult;
        });

        // Hiện thông báo
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                apiResult ? "Đã lưu vào danh sách xem" : "Đã bỏ "),
            duration: const Duration(seconds: 1),
            action: apiResult
                ? SnackBarAction(
                    label: "XEM DS",
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const MarkdownRecipeScreen())); // Chuyển trang Bookmark
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      // Nếu lỗi mạng, hoàn tác lại
      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Lỗi kết nối, vui lòng thử lại")),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  void _parseData() {
    final data = widget.recipeData ?? {};

    _name = data['name'] ?? 'Món ăn không tên';
    _time = "${data['time'] ?? data['cooking_time'] ?? '30'} phút";
    _calories = "${data['calories'] ?? 0}";
    _servings = "${data['servings'] ?? 2} người";

    _difficulty = data['difficulty'] ?? 'Dễ';
    _chefTips = data['chef_tips'];

    String desc = data['description'] ?? '';
    _description = (desc.trim().isNotEmpty)
        ? desc
        : 'Món ăn thơm ngon, bổ dưỡng và dễ làm tại nhà.';

    // Ảnh
    String? inputImg = data['image'];
    if (inputImg != null && inputImg.startsWith("http")) {
      _passedImageUrl = inputImg;
    } else {
      _passedImageUrl = null;
    }

    // Xử lý Video (YouTube & Uploaded)
    String? rawVideo;

    // 1. Lấy dữ liệu thô
    if (data['video'] != null) {
      if (data['video'] is String) {
        rawVideo = data['video'];
      } else if (data['video'] is Map) {
        rawVideo = data['video']['url']; 
      }
    }
    
    // Fallback
    if (rawVideo == null || rawVideo.isEmpty) {
       if (data['videoUrl'] is String) rawVideo = data['videoUrl'];
    }

    // 2. Phân loại video
    if (rawVideo != null && rawVideo.isNotEmpty) {
      if (rawVideo.contains('youtube.com') || rawVideo.contains('youtu.be')) {
        String? videoId = YoutubePlayer.convertUrlToId(rawVideo);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
          _hasYoutubeVideo = true;
        }
      } 
      else {
        String finalUrl = rawVideo;
        if (!finalUrl.startsWith('http')) {
           if (finalUrl.startsWith('/')) {
              finalUrl = '${RecipeService.domain}$finalUrl';
           } else {
              finalUrl = '${RecipeService.domain}/$finalUrl';
           }
        }

        _uploadedVideoUrl = finalUrl;
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_uploadedVideoUrl!))
          ..initialize().then((_) {
            if (mounted) setState(() {}); 
          }).catchError((error) {
             print("❌ Lỗi load video: $error");
          });
        _hasUploadedVideo = true;
      }
    }

    // Nguyên liệu
    var rawIng = data['ingredients'] ??
        data['all_ingredients'] ??
        data['ingredients_used'];

    if (rawIng is List && rawIng.isNotEmpty) {
      _ingredients = rawIng.map((item) {
        if (item is Map) {
          String name = item['name'] ?? 'Nguyên liệu';
          dynamic qVal = item['quantity'];
          String qty = '';
          if (qVal != null) {
            double d = double.tryParse(qVal.toString()) ?? 0;
            if (d > 0) {
              qty = (d % 1 == 0) ? d.toInt().toString() : d.toString();
            }
          }
          String unit = item['unit'] ?? '';
          String amount = "";
          if (qty.isNotEmpty && qty != "0") amount += "$qty ";
          if (unit.isNotEmpty) amount += unit;

          return {"amount": amount.trim(), "name": name.trim()};
        } else {
          return {"amount": "", "name": item.toString()};
        }
      }).toList().cast<Map<String, String>>();
    } else {
      _ingredients = [
        {"amount": "", "name": "Đang cập nhật nguyên liệu..."}
      ];
    }

    // Cách làm
    var rawInst = data['steps'] ?? data['instructions'];
    if (rawInst is List && rawInst.isNotEmpty) {
      _instructions = rawInst.map((item) {
        if (item is Map) {
          return item['description']?.toString() ?? "Bước không có mô tả";
        } else {
          String step = item.toString();
          return step.replaceAll(RegExp(r'^(Bước|Step)\s*\d+[:.]?\s*|^\d+[:.]\s*', caseSensitive: false), '').trim();
        }
      }).toList().cast<String>();
    } else {
      _instructions = ['Hướng dẫn đang cập nhật...'];
    }

    // Dinh dưỡng
    dynamic nutritionAnalysis = data['nutritionAnalysis'];
    if (nutritionAnalysis != null && nutritionAnalysis is Map) {
      _nutritionData = {
        'calories': nutritionAnalysis['calories']?.toString() ?? _calories,
        'protein': _safeParse(nutritionAnalysis['protein']),
        'carbs': _safeParse(nutritionAnalysis['carbs']),
        'fat': _safeParse(nutritionAnalysis['fat']),
        'sugars': _safeParse(nutritionAnalysis['sugars']),
        'sodium': _safeParse(nutritionAnalysis['sodium']),
      };
      _calories = _nutritionData['calories'].toString();
    } else {
      final macros = data['macros'] ?? {};
      double protein = _safeParse(macros['protein']);
      double carbs = _safeParse(macros['carbs']);
      double fat = _safeParse(macros['fat']);

      if (protein == 0 && carbs == 0 && fat == 0) {
        double totalCal = double.tryParse(_calories) ?? 0;
        if (totalCal > 0) {
          protein = (totalCal * 0.3) / 4;
          carbs = (totalCal * 0.5) / 4;
          fat = (totalCal * 0.2) / 9;
        }
      }
      _nutritionData = {
        'calories': _calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sugars': _safeParse(data['sugars']),
        'sodium': _safeParse(data['sodium']),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildContentScrollable(context),
          _buildOverlayButtons(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    if (_passedImageUrl != null && _passedImageUrl!.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 400.0,
        color: kColorAlternate,
        child: Image.network(
          _passedImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
              color: Colors.grey, child: const Icon(Icons.broken_image)),
        ),
      );
    }
    return FutureBuilder<String>(
      future: ImageSearchHelperDetail.findImage(_name),
      builder: (context, snapshot) {
        String displayUrl = "";
        if (snapshot.hasData && snapshot.data!.isNotEmpty)
          displayUrl = snapshot.data!;
        return Container(
          width: double.infinity,
          height: 400.0,
          color: kColorAlternate,
          child: displayUrl.isNotEmpty
              ? Image.network(displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50)))
              : const Center(
                  child: CircularProgressIndicator(color: kColorPrimary)),
        );
      },
    );
  }

  Widget _buildOverlayButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircleButton(
                icon: Icons.arrow_back_ios_new,
                color: kColorPrimaryText,
                onPressed: () => Navigator.of(context).pop()),
            
            Row(
              children: [
                if (widget.isOwner) ...[
                   _buildCircleButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng sửa đang cập nhật")));
                      }),
                   const SizedBox(width: 12),
                   _buildCircleButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: () {
                          _showDeleteConfirmDialog();
                      }),
                ] else ...[
                   _buildCircleButton(
                    icon: _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    color: _isFavorited ? kColorPrimary : kColorPrimaryText,
                    onPressed: _toggleFavorite,
                   ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa công thức?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              // Gọi API xóa ở đây nếu cần
              // await RecipeService.deleteRecipe(...)
              Navigator.pop(ctx);
              Navigator.pop(context, true); 
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
          ]),
      child: IconButton(
          icon: Icon(icon, color: color, size: 24), onPressed: onPressed),
    );
  }

  // ... (Phần còn lại của UI: _buildContentScrollable, _buildVideoSection, v.v... Giữ nguyên không đổi)
  // Chỉ copy phần Widget _buildContentScrollable trở xuống từ code cũ của bạn là được.
  // Vì logic UI hiển thị không thay đổi, chỉ thay đổi logic xử lý Like.
  
  Widget _buildContentScrollable(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 320.0),
          Container(
            decoration: const BoxDecoration(
                color: kColorBackground,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5))
                ]),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),

                _buildRecipeInfo(),

                const SizedBox(height: 16),
                _buildChefTipsSection(),

                const SizedBox(height: 24),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giới thiệu',
                        style: GoogleFonts.inter(
                            color: kColorPrimaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: kColorCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10)
                          ]),
                      child: Text(_description,
                          style: GoogleFonts.inter(
                              color: kColorSecondaryText,
                              fontSize: 15,
                              height: 1.6)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                
                _buildVideoSection(),

                const SizedBox(height: 32),
                _buildIngredientsSection(),

                const SizedBox(height: 32),
                _buildInstructionsSection(),

                const SizedBox(height: 32),
                _buildNutritionSection(),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // (Các hàm build UI con khác giữ nguyên như cũ...)
  // Bạn có thể copy lại toàn bộ phần build UI từ file cũ của bạn vào đây.
  // Code trên chỉ focus sửa logic State và API call.
  
  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Video Hướng Dẫn",
            style: GoogleFonts.inter(
                color: kColorPrimaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        if (_hasYoutubeVideo && _youtubeController != null) ...[
          Text("Video YouTube",
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true)),
          const SizedBox(height: 16),
        ] else if (_hasUploadedVideo) ...[
        ] else ...[
           Text("Video YouTube: Không có",
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 14, fontStyle: FontStyle.italic)),
           const SizedBox(height: 16),
        ],

        if (_hasUploadedVideo && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) ...[
          Text("Video Tải Lên",
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_videoPlayerController!),
                  VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_videoPlayerController!.value.isPlaying) {
                          _videoPlayerController!.pause();
                        } else {
                          _videoPlayerController!.play();
                        }
                      });
                    },
                    child: Center(
                      child: Icon(
                        _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ] else if (_hasYoutubeVideo) ...[
        ] else ...[
           Text("Video Tải Lên: Không có",
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildChefTipsSection() {
    if (_chefTips == null || _chefTips!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text("Độ khó: $_difficulty",
              style: const TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text("Mẹo đầu bếp: $_chefTips",
                  style: const TextStyle(
                      color: kColorSecondaryText,
                      fontStyle: FontStyle.italic))),
        ])
      ]),
    );
  }

  Widget _buildRecipeInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_name,
          style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kColorPrimaryText,
              height: 1.2)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildInfoChip(Icons.access_time_filled, _time, Colors.blueAccent),
          _buildInfoChip(Icons.local_fire_department, '$_calories Kcal',
              Colors.orangeAccent),
          _buildInfoChip(Icons.people, _servings, Colors.green),
        ],
      )
    ]);
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
                color: kColorPrimaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13))
      ]),
    );
  }

  Widget _buildIngredientsSection() {
    if (_ingredients.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nguyên Liệu',
          style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: kColorCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ]),
        child: Column(
          children: _ingredients.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == _ingredients.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: kColorAlternate.withOpacity(0.5)))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, color: kColorPrimary, size: 8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.4,
                              color: kColorPrimaryText),
                          children: [
                            if (item['amount']!.isNotEmpty)
                              TextSpan(
                                  text: '${item['amount']} ',
                                  style: const TextStyle(
                                      color: kColorSecondaryText,
                                      fontWeight: FontWeight.w500)),
                            TextSpan(
                                text: item['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildInstructionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cách Làm',
          style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ..._instructions.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: kColorPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: kColorPrimary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]),
                  child: Center(
                      child: Text("${e.key + 1}",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 16),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: kColorCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5)
                          ]),
                      child: Text(e.value,
                          style: GoogleFonts.inter(
                              color: kColorPrimaryText,
                              fontSize: 15,
                              height: 1.5)))),
            ]),
          )),
    ]);
  }

  Widget _buildNutritionSection() {
    double protein = _nutritionData['protein'] ?? 0;
    double carbs = _nutritionData['carbs'] ?? 0;
    double fat = _nutritionData['fat'] ?? 0;
    double sugars = _nutritionData['sugars'] ?? 0;
    double sodium = _nutritionData['sodium'] ?? 0;

    double totalMass = protein + carbs + fat;
    if (totalMass == 0) totalMass = 1;

    int getPercent(double value) {
      return ((value / totalMass) * 100).round();
    }

    bool showTitle(double value) {
      return getPercent(value) >= 10;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dinh Dưỡng',
          style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: kColorCard, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(children: [
              SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                                color: kColorProtein,
                                value: protein,
                                title: '${getPercent(protein)}%',
                                showTitle: showTitle(protein),
                                radius: 30,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                            PieChartSectionData(
                                color: kChartCarbs,
                                value: carbs,
                                title: '${getPercent(carbs)}%',
                                showTitle: showTitle(carbs),
                                radius: 30,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                            PieChartSectionData(
                                color: kChartFat,
                                value: fat,
                                title: '${getPercent(fat)}%',
                                showTitle: showTitle(fat),
                                radius: 30,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ])),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_calories,
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kColorPrimaryText)),
                          Text("Kcal",
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: kColorSecondaryText)),
                        ],
                      )
                    ],
                  )),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    _Indicator(
                        color: kColorProtein,
                        text:
                            'Protein (${protein.toInt()}g - ${getPercent(protein)}%)'),
                    const SizedBox(height: 8),
                    _Indicator(
                        color: kChartCarbs,
                        text:
                            'Carbs (${carbs.toInt()}g - ${getPercent(carbs)}%)'),
                    const SizedBox(height: 8),
                    _Indicator(
                        color: kChartFat,
                        text: 'Fat (${fat.toInt()}g - ${getPercent(fat)}%)'),
                  ]))
            ]),
            const SizedBox(height: 20),
            const Divider(color: kColorAlternate),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Chi tiết khác (Đường, Muối...)',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: kColorPrimaryText,
                      fontWeight: FontWeight.bold),
                ),
                children: [
                  _buildDetailRow('Đường (Sugar)', sugars, 'g'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Muối (Sodium)', sodium, 'mg'),
                ],
              ),
            ),
          ],
        ),
      )
    ]);
  }

  Widget _buildDetailRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: kColorSecondaryText, fontSize: 14)),
          Text('${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.inter(
                  color: kColorPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const _Indicator({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 14, color: kColorPrimaryText)))
    ]);
  }
}

class ImageSearchHelperDetail {
  static const String _apiKey = "AIzaSyAksWw3AwgHO7SaQw5bQZZDBkGQh_4G-88";
  static const String _cxId = "81194332729ef486f";
  static final Map<String, String> _cache = {};
  static Future<String> findImage(String query) async {
    if (_cache.containsKey(query)) return _cache[query]!;
    final String searchUrl =
        "https://www.googleapis.com/customsearch/v1?q=$query cooked dish -mì -instant -gói -pack -flavour&cx=$_cxId&key=$_apiKey&searchType=image&num=1&imgSize=large";
    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          String url = data['items'][0]['link'];
          _cache[query] = url;
          return url;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    String fallback =
        "https://image.pollinations.ai/prompt/${Uri.encodeComponent(query)}%20cooked%20dish";
    _cache[query] = fallback;
    return fallback;
  }
}