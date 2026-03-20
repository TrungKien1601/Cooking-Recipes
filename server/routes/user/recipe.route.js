const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken'); 
const recipeController = require('../../controllers/user/recipe.controller'); 
// Import đúng các config multer tương ứng
const { uploadVideo, uploadImage, uploadMixed } = require('../../config/multer'); 

const JwtUtil = require('../../utils/JwtUtils'); 
require("dotenv").config();

// 1. Middleware Bắt buộc đăng nhập
const JWT = JwtUtil.checkToken;

// 2. Middleware Admin (Giả sử bạn có hàm này trong JwtUtil hoặc viết inline)
const isAdmin = (req, res, next) => {
    if (req.decoded && (req.decoded.role === 'admin' || req.decoded.role?.roleName === 'admin')) {
        next();
    } else {
        return res.status(403).json({ message: "Bạn không có quyền thực hiện thao tác này" });
    }
};

// 3. Middleware Không bắt buộc đăng nhập (User Optional)
const checkUserOptional = (req, res, next) => {
    let token = req.headers['x-access-token'] || req.headers['authorization'];
    if (token && token.startsWith('Bearer ')) {
        token = token.slice(7, token.length);
    }

    if (token) {
        jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
            if (!err) {
                req.decoded = decoded; 
            }
            // Token lỗi hay hết hạn thì vẫn cho qua dưới dạng guest (req.decoded = undefined)
            next();
        });
    } else {
        next();
    }
};

// ==============================================
// 1. NHÓM NOTIFICATION 
// ==============================================
router.get('/notifications', JWT, recipeController.getMyNotifications);
router.put('/notifications/:id/read', JWT, recipeController.markNotificationRead);
router.delete('/notifications/:id', JWT, recipeController.deleteNotification);

// ==============================================
// 2. NHÓM UPLOAD (Sử dụng middleware chuyên biệt)
// ==============================================
// Dùng uploadVideo để chỉ nhận file mp4, mov...
router.post('/upload-video', JWT, uploadVideo.single('video'), recipeController.uploadVideo);

// ==============================================
// 3. NHÓM TƯƠNG TÁC (Saved)
// ==============================================
router.get('/saved', JWT, recipeController.getSavedRecipes);
router.post('/toggle-save', JWT, recipeController.toggleSave);

// ==============================================
// 4. NHÓM TIỆN ÍCH (AI, Search, Config)
// ==============================================
router.get('/init-create', JWT, recipeController.getRecipeTags); 
router.get('/ingredients/search', JWT, recipeController.searchIngredients);
router.post('/analyze', JWT, recipeController.analyzeNutrition); 

// ==============================================
// 5. NHÓM RECIPE CRUD
// ==============================================
// Lấy danh sách (Optional Auth để check isSaved)
router.get('/', checkUserOptional, recipeController.getAllRecipes); 

// Tạo bài (Dùng uploadImage để chỉ nhận file ảnh)
router.post('/', JWT, uploadImage.single('image'), recipeController.createRecipe);

// ==============================================
// 6. CÁC ROUTE CÓ PARAM :id (ĐỂ CUỐI CÙNG)
// ==============================================

// [QUAN TRỌNG] Route Admin duyệt bài -> Thêm middleware isAdmin
router.put('/:id/status', JWT, isAdmin, recipeController.updateStatus);

// Lấy chi tiết
router.get('/:id', checkUserOptional, recipeController.getRecipeById); 

// Cập nhật bài (Chỉ nhận ảnh)
router.put('/:id', JWT, uploadImage.single('image'), recipeController.updateRecipe);

// Xóa bài
router.delete('/:id', JWT, recipeController.deleteRecipe);

module.exports = router;