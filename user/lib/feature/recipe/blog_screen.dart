import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../services/util_service.dart';
import '../services/recipe_service.dart';

// ... (Các hằng số màu sắc giữ nguyên) ...
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
  final bool showSaveButton;

  const BlogScreen({
    super.key,
    required this.recipeData,
    this.isOwner = false,
    this.showSaveButton = true,
  });

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  // ... (Các biến state giữ nguyên) ...
  bool _isSaved = false;
  bool _isLoadingDetail = false;

  // Data fields
  String _name = '';
  String _time = '';
  String _calories = '';
  String _servings = '';
  String _description = '';
  String? _passedImageUrl;
  String _difficulty = 'Trung bình';
  String? _chefTips;

  // Tags strings
  String _strDietTags = '';
  String _strMealTimeTags = '';
  String _strRegionTags = '';
  String _strDishTypeTags = '';

  Map<String, dynamic> _nutritionData = {
    'calories': 0,
    'protein': 0.0,
    'carbs': 0.0,
    'fat': 0.0,
    'sugars': 0.0,
    'sodium': 0.0
  };

  List<Map<String, String>> _ingredients = [];
  List<String> _instructions = [];

  // Controllers
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  bool _hasYoutubeVideo = false;
  bool _hasUploadedVideo = false;
  String? _uploadedVideoUrl;

  @override
  void initState() {
    super.initState();
    _parseData(widget.recipeData);

    if (widget.recipeData != null) {
      _isSaved = widget.recipeData['isSaved'] ??
          widget.recipeData['isFavorite'] ??
          false;

      final String? id = widget.recipeData['_id'] ?? widget.recipeData['id'];
      bool isDataIncomplete = _instructions.isEmpty || _ingredients.isEmpty;
      
      if (id != null && id.isNotEmpty && isDataIncomplete) {
        _fetchFullRecipeDetail(id);
      }
    }
  }

  Future<void> _fetchFullRecipeDetail(String id) async {
    if (!mounted) return;
    setState(() => _isLoadingDetail = true);

    try {
      final result = await RecipeService.getRecipeDetail(id);
      if (result['success'] == true && result['data'] != null) {
        if (mounted) {
          setState(() {
            _parseData(result['data']);
            if (result['data']['isSaved'] != null) {
              _isSaved = result['data']['isSaved'];
            }
          });
        }
      }
    } catch (e) {
      print("Lỗi tải chi tiết: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _handleToggleSave() async {
    String? id = widget.recipeData['_id'] ?? widget.recipeData['id'];
    
    if (id == null) {
       _showSnackBar("Món này chưa được đồng bộ ID. Vui lòng thử lại sau.", isSuccess: false);
       return;
    }

    try {
      setState(() => _isSaved = !_isSaved);

      final result = await RecipeService.toggleSave(id);

      if (result['success'] == true) {
        bool serverStatus = result['isSaved'] ?? false;
        if (mounted) {
          setState(() => _isSaved = serverStatus);
          _showSnackBar(serverStatus ? "Đã lưu vào bộ sưu tập" : "Đã bỏ lưu",
              isSuccess: serverStatus);
        }
      } else {
        if (mounted) {
          setState(() => _isSaved = !_isSaved);
          _showSnackBar("Lỗi thao tác", isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaved = !_isSaved);
        _showSnackBar("Lỗi kết nối", isSuccess: false);
      }
    }
  }

  // ... (Các hàm _showSnackBar, dispose, _safeParse, _parseTagsToString giữ nguyên) ...
  void _showSnackBar(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? kColorPrimary : kColorSecondaryText,
        duration: const Duration(seconds: 2),
      ),
    );
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
      if (value.isEmpty) return 0.0;
      String clean = value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  String _parseTagsToString(dynamic tags) {
    if (tags == null) return "Chưa cập nhật";
    if (tags is String) return tags;
    if (tags is List) {
      if (tags.isEmpty) return "Chưa cập nhật";
      return tags
          .map((t) {
            if (t is Map) return t['name'] ?? "";
            return t.toString();
          })
          .where((s) => s.toString().isNotEmpty)
          .join(", ");
    }
    return tags.toString();
  }

  void _parseData(dynamic data) {
    if (data == null) return;

    _name = data['name'] ?? 'Món ăn không tên';
    _time = "${data['cookTimeMinutes'] ?? data['time'] ?? '30'} phút";
    _difficulty = data['difficulty'] ?? 'Trung bình';
    _servings = "${data['servings'] ?? 2} người";
    _chefTips = data['chef_tips'];

    dynamic nut = data['nutritionAnalysis'] ?? data['macros'];
    _calories = "${nut?['calories'] ?? data['calories'] ?? 0}";

    if (nut != null && nut is Map) {
      _nutritionData = {
        'calories': nut['calories']?.toString() ?? _calories,
        'protein': _safeParse(nut['protein']),
        'carbs': _safeParse(nut['carbs']),
        'fat': _safeParse(nut['fat']),
        'sugars': _safeParse(nut['sugars']),
        'sodium': _safeParse(nut['sodium']),
      };
    }
    _strDietTags = _parseTagsToString(data['dietTags']);
    _strMealTimeTags = _parseTagsToString(data['mealTimeTags']);
    _strRegionTags = _parseTagsToString(data['regionTags']);
    _strDishTypeTags = _parseTagsToString(data['dishtypeTags']);
    String desc = data['description'] ?? '';
    _description = (desc.trim().isNotEmpty)
        ? desc
        : 'Món ăn thơm ngon, bổ dưỡng và dễ làm tại nhà.';

    // Fix ảnh
    String? inputImg = data['image'] ?? data['image_url'];
    if (inputImg != null && inputImg.isNotEmpty) {
      // Bỏ qua ảnh placeholder của AI
      if (inputImg.contains("placehold.co") || inputImg.contains("text=")) {
         _passedImageUrl = null;
      } else {
        if (inputImg.startsWith("http")) {
          _passedImageUrl = inputImg;
        } else {
          String cleanPath = inputImg.startsWith('/') ? inputImg.substring(1) : inputImg;
          _passedImageUrl = '${RecipeService.domain}/$cleanPath';
        }
      }
    }                                                                                   

    String? rawVideo = data['video'];
    if (rawVideo == null || rawVideo.isEmpty) {
      if (data['videoUrl'] is String) rawVideo = data['videoUrl'];
    }

    if (rawVideo != null && rawVideo.isNotEmpty) {
      if (rawVideo.contains('youtube.com') || rawVideo.contains('youtu.be')) {
        String? videoId = YoutubePlayer.convertUrlToId(rawVideo);
        if (videoId != null) {
          if (_youtubeController == null) {
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
            );
          } else {
            _youtubeController!.load(videoId);
            _youtubeController!.pause();
          }
          _hasYoutubeVideo = true;
          _hasUploadedVideo = false;
        }
      } else {
        String finalUrl = rawVideo;
        if (!finalUrl.startsWith('http')) {
          String cleanPath =
              finalUrl.startsWith('/') ? finalUrl.substring(1) : finalUrl;
          finalUrl = '${RecipeService.domain}/$cleanPath';
        }

        if (_uploadedVideoUrl != finalUrl) {
          _uploadedVideoUrl = finalUrl;
          _videoPlayerController?.dispose();
          _videoPlayerController =
              VideoPlayerController.networkUrl(Uri.parse(_uploadedVideoUrl!))
                ..initialize().then((_) {
                  if (mounted) setState(() {});
                }).catchError((e) {});

          _hasUploadedVideo = true;
          _hasYoutubeVideo = false;
        }
      }
    }

    var rawIng = data['ingredients'] ?? data['all_ingredients'];
    if (rawIng is List && rawIng.isNotEmpty) {
      _ingredients = rawIng.map((item) {
            if (item is Map) {
              String name = item['name'] ?? 'Nguyên liệu';
              dynamic qVal = item['quantity'];
              String qty = '';
              if (qVal != null) {
                double d = _safeParse(qVal.toString());
                if (d > 0) qty = (d % 1 == 0) ? d.toInt().toString() : d.toString();
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
      _ingredients = [{"amount": "", "name": "Đang cập nhật nguyên liệu..."}];
    }

    var rawInst = data['steps'] ?? data['instructions'];
    if (rawInst is List && rawInst.isNotEmpty) {
      _instructions = rawInst.map((item) {
            if (item is Map) {
              return item['description']?.toString() ?? "Bước không có mô tả";
            } else {
              return item.toString()
                  .replaceAll(RegExp(r'^(Bước|Step)\s*\d+[:.]?\s*|^\d+[:.]\s*', caseSensitive: false), '')
                  .trim();
            }
          }).toList().cast<String>();
    } else {
      _instructions = ['Hướng dẫn đang cập nhật...'];
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
          if (_isLoadingDetail)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                    child: CircularProgressIndicator(color: kColorPrimary)),
              ),
            )
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
              color: Colors.grey,
              child: const Icon(Icons.broken_image,
                  size: 50, color: Colors.white54)),
        ),
      );
    }
    return FutureBuilder<String>(
      future: ImageSearchHelperDetail.findImage(_name),
      builder: (context, snapshot) {
        String displayUrl = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : "";
        return Container(
          width: double.infinity,
          height: 400.0,
          color: kColorAlternate,
          child: displayUrl.isNotEmpty
              ? Image.network(displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox())
              : const Center(
                  child: Icon(Icons.restaurant, size: 60, color: Colors.grey)),
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
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text("Tính năng sửa đang cập nhật")))),
                  const SizedBox(width: 12),
                  _buildCircleButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: _showDeleteConfirmDialog),
                ] else if (widget.showSaveButton) ...[
                  _buildCircleButton(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? kColorPrimary : kColorPrimaryText,
                    onPressed: _handleToggleSave,
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
              onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              await RecipeService.deleteRecipe(widget.recipeData['_id']);
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
                const SizedBox(height: 24),
                _buildTagsInfoSection(),
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

  Widget _buildTagsInfoSection() {
    List<Widget> chips = [];
    if (_strMealTimeTags.isNotEmpty && _strMealTimeTags != "Chưa cập nhật")
      chips
          .add(_buildInfoChip(Icons.schedule, _strMealTimeTags, Colors.purple));
    if (_strRegionTags.isNotEmpty && _strRegionTags != "Chưa cập nhật")
      chips.add(_buildInfoChip(Icons.public, _strRegionTags, Colors.teal));
    if (_strDishTypeTags.isNotEmpty && _strDishTypeTags != "Chưa cập nhật")
      chips.add(_buildInfoChip(
          Icons.restaurant_menu, _strDishTypeTags, Colors.deepOrange));
    if (_strDietTags.isNotEmpty && _strDietTags != "Chưa cập nhật")
      chips.add(_buildInfoChip(Icons.spa, _strDietTags, kColorPrimary));

    Color difficultyColor = Colors.green;
    if (_difficulty == 'Trung bình') difficultyColor = Colors.orange;
    if (_difficulty == 'Khó') difficultyColor = Colors.red;
    chips.add(_buildInfoChip(
        Icons.signal_cellular_alt, "Độ khó: $_difficulty", difficultyColor));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Thông tin phân loại",
            style: GoogleFonts.inter(
                color: kColorPrimaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kColorCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Wrap(spacing: 10, runSpacing: 10, children: chips),
        ),
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
          const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text("Mẹo đầu bếp: $_chefTips",
                  style: const TextStyle(
                      color: kColorSecondaryText, fontStyle: FontStyle.italic)))
        ])
      ]),
    );
  }

  Widget _buildVideoSection() {
    if (!_hasYoutubeVideo && !_hasUploadedVideo) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Video Hướng Dẫn",
          style: GoogleFonts.inter(
              color: kColorPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      if (_hasYoutubeVideo && _youtubeController != null) ...[
        ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true)),
      ] else if (_hasUploadedVideo &&
          _videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) ...[
        AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(alignment: Alignment.bottomCenter, children: [
              VideoPlayer(_videoPlayerController!),
              VideoProgressIndicator(_videoPlayerController!,
                  allowScrubbing: true),
              GestureDetector(
                onTap: () => setState(() =>
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play()),
                child: Center(
                    child: Icon(
                        _videoPlayerController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 50,
                        color: Colors.white.withOpacity(0.7))),
              )
            ]),
          ),
        ),
      ]
    ]);
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
      Wrap(spacing: 10, runSpacing: 10, children: [
        _buildInfoChip(Icons.access_time_filled, _time, Colors.blueAccent),
        _buildInfoChip(Icons.local_fire_department, '$_calories Kcal',
            Colors.orangeAccent),
        _buildInfoChip(Icons.people, _servings, Colors.green),
      ])
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
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
                color: kColorPrimaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        )
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
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, color: kColorPrimary, size: 8)),
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ])))
              ]),
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
    double protein = _nutritionData['protein'] ?? 0.0;
    double carbs = _nutritionData['carbs'] ?? 0.0;
    double fat = _nutritionData['fat'] ?? 0.0;
    double sugars = _nutritionData['sugars'] ?? 0.0;
    double sodium = _nutritionData['sodium'] ?? 0.0;

    double totalMass = protein + carbs + fat;
    bool isDataEmpty = totalMass == 0;
    if (totalMass == 0) totalMass = 1;

    int getPercent(double value) => ((value / totalMass) * 100).round();
    bool showTitle(double value) => getPercent(value) >= 10;

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
        child: Column(children: [
          Row(children: [
            SizedBox(
                height: 150,
                width: 150,
                child: Stack(alignment: Alignment.center, children: [
                  PieChart(PieChartData(
                      sectionsSpace: isDataEmpty ? 0 : 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: -90,
                      sections: isDataEmpty
                          ? [
                              PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.1),
                                  value: 1,
                                  title: '',
                                  radius: 30)
                            ]
                          : [
                              if (protein > 0)
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
                              if (carbs > 0)
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
                              if (fat > 0)
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
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_calories,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kColorPrimaryText)),
                    Text("Kcal",
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kColorSecondaryText))
                  ])
                ])),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  _Indicator(
                      color: kColorProtein,
                      text: isDataEmpty
                          ? 'Protein (0g)'
                          : 'Protein (${protein.toInt()}g - ${getPercent(protein)}%)'),
                  const SizedBox(height: 8),
                  _Indicator(
                      color: kChartCarbs,
                      text: isDataEmpty
                          ? 'Carbs (0g)'
                          : 'Carbs (${carbs.toInt()}g - ${getPercent(carbs)}%)'),
                  const SizedBox(height: 8),
                  _Indicator(
                      color: kChartFat,
                      text: isDataEmpty
                          ? 'Fat (0g)'
                          : 'Fat (${fat.toInt()}g - ${getPercent(fat)}%)'),
                ]))
          ]),
          const SizedBox(height: 20),
          const Divider(color: kColorAlternate),
          Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Chi tiết khác (Đường, Muối...)',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: kColorPrimaryText,
                          fontWeight: FontWeight.bold)),
                  children: [
                    _buildDetailRow('Đường (Sugar)', sugars, 'g'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Muối (Sodium)', sodium, 'mg')
                  ])),
        ]),
      )
    ]);
  }

  Widget _buildDetailRow(String label, double value, String unit) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style:
                  GoogleFonts.inter(color: kColorSecondaryText, fontSize: 14)),
          Text('${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.inter(
                  color: kColorPrimaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14))
        ]));
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: GoogleFonts.inter(fontSize: 14, color: kColorPrimaryText)))
    ]);
  }
}

class ImageSearchHelperDetail {
  static final Map<String, String> _cache = {};

  static Future<String> findImage(String query) async {
    if (_cache.containsKey(query)) return _cache[query]!;
    final String? serverImage = await UtilService.searchImage(query);
    if (serverImage != null && serverImage.isNotEmpty) {
      _cache[query] = serverImage;
      return serverImage;
    }
    String fallback =
        "https://image.pollinations.ai/prompt/${Uri.encodeComponent(query)}%20cooked%20dish%20food";
    _cache[query] = fallback;
    return fallback;
  }
}