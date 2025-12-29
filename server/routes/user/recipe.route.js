const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken'); 

// Import Controller & Config
const recipeController = require('../../controllers/user/recipe.controller'); 
const upload = require('../../config/multer');
const video = require('../../config/video'); 
const JwtUtil = require('../../utils/JwtUtils'); 

require("dotenv").config();

// 1. Bắt buộc đăng nhập (Lấy từ JwtUtils)
const JWT = JwtUtil.checkToken;

// 2. Không bắt buộc đăng nhập (Dùng cho xem chi tiết/danh sách bài viết)
const checkUserOptional = (req, res, next) => {
    let token = req.headers['x-access-token'] || req.headers['authorization'];
    
    if (token && token.startsWith('Bearer ')) {
        token = token.slice(7, token.length);
    }

    if (token) {
        jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
            if (!err) {
                req.decoded = decoded; // Lưu vào decoded cho giống JwtUtil
            }
            // Dù lỗi hay không cũng next(), vì đây là optional
            next();
        });
    } else {
        next();
    }
};

// ==============================================
// 1. NHÓM NOTIFICATION 
// ==============================================

// Lấy danh sách thông báo
router.get('/notifications', JWT, recipeController.getMyNotifications);

// Đánh dấu đã đọc
router.put('/notifications/:id/read', JWT, recipeController.markNotificationRead);

// Xóa thông báo (Nút thùng rác Flutter)
router.delete('/notifications/:id', JWT, recipeController.deleteNotification);

router.post('/upload-video', JWT, video.single('video'), recipeController.uploadVideo);

// Lấy danh sách bài viết đã yêu thích
router.get('/favorites', JWT, recipeController.getFavorites);

// Thả tim / Bỏ tim bài viết
router.post('/toggle-like', JWT, recipeController.toggleLike);


// ==============================================
// 3. NHÓM TIỆN ÍCH (AI, Search, Config)
// ==============================================

// Lấy tags init cho màn hình tạo recipe (Giờ ăn, vùng miền...)
router.get('/init-create', JWT, recipeController.getRecipeTags); 

// Tìm kiếm nguyên liệu (Autocomplete)
router.get('/ingredients/search', JWT, recipeController.searchIngredients);

// Phân tích dinh dưỡng (AI Gemini)
router.post('/analyze', JWT, recipeController.analyzeNutrition); 


// ==============================================
// 4. NHÓM RECIPE CRUD (CƠ BẢN)
// ==============================================

// Lấy danh sách bài viết (Có filter, search)
// Dùng checkUserOptional để check xem user có like bài viết chưa (nếu đã login)
router.get('/', checkUserOptional, recipeController.getAllRecipes); 

// Tạo bài viết mới (Upload ảnh)
router.post('/', JWT, upload.single('image'), recipeController.createRecipe);


// ==============================================
// 5. CÁC ROUTE CÓ PARAM :id (BẮT BUỘC ĐỂ CUỐI CÙNG)
// ==============================================

// Admin duyệt bài / Từ chối bài (Cập nhật trạng thái)
router.put('/:id/status', JWT, recipeController.updateStatus);

// Lấy chi tiết bài viết
router.get('/:id', checkUserOptional, recipeController.getRecipeById); 

// Cập nhật bài viết (Upload ảnh mới nếu có)
router.put('/:id', JWT, upload.single('image'), recipeController.updateRecipe);

// Xóa bài viết
router.delete('/:id', JWT, recipeController.deleteRecipe);

module.exports = router;    