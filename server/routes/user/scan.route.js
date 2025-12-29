const express = require('express');
const router = express.Router();
// Import Controller & Config
const scanController = require('../../controllers/user/scan.controller'); 
const uploads = require('../../config/multer');
const JwtUtil = require('../../utils/JwtUtils');

// Định nghĩa Middleware check token cho gọn
const JWT = JwtUtil.checkToken;

// ============================================================
// 1. NHÓM SCAN & AI (Public - Không bắt buộc Login)
// ============================================================

// Quét mã vạch (Barcode)
router.post('/scan/barcode', scanController.scanBarcode); 

// Quét ảnh nguyên liệu (AI detect)
router.post('/scan/image', uploads.single('image'), scanController.scanImage);

// Gợi ý món ăn nhanh cho khách (Guest Mode - dựa trên list tên nguyên liệu)
router.post('/scan/suggest-guest', scanController.suggestByIngredients);


// ============================================================
// 2. NHÓM UPLOAD TIỆN ÍCH (Cần Login)
// ============================================================

// Upload 1 ảnh món ăn (Lưu avatar, ...)
router.post('/scan/upload-food', JWT, uploads.single('image'), scanController.uploadFoodImage);

// Upload nhiều ảnh (Logic inline)
router.post('/scan/upload-multiple-foods', JWT, uploads.array('images', 10), (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ success: false, message: 'Chưa gửi file ảnh nào' });
        }
        
        // Trả về danh sách đường dẫn tương đối (Frontend sẽ ghép với Base URL)
        // Ví dụ: uploads/abc.jpg
        const filePaths = req.files.map(file => `uploads/${file.filename}`);
        
        return res.status(200).json({
            success: true,
            message: `Đã upload ${filePaths.length} ảnh`,
            filePaths: filePaths 
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Lỗi upload ảnh" });
    }
});


// ============================================================
// 3. QUẢN LÝ TỦ LẠNH (PANTRY - Cần Login)
// ============================================================

// Lấy danh sách đồ trong tủ
router.get('/pantry', JWT, scanController.getPantry);

// Thêm món vào tủ (Thủ công hoặc từ kết quả Scan)
router.post('/pantry', JWT, scanController.addToPantry);

// Sửa thông tin món (Số lượng, HSD, ...)
router.put('/pantry/:id', JWT, scanController.updateItem);

// Xóa món khỏi tủ
router.delete('/pantry/:id', JWT, scanController.deleteItem);


// ============================================================
// 4. GỢI Ý & LỊCH SỬ (CHEF MODE - Cần Login)
// ============================================================

// AI Chef: Gợi ý công thức dựa trên toàn bộ/một phần đồ trong Pantry
router.post('/pantry/suggest-chef', JWT, scanController.suggestRecipes); 

// Lấy lịch sử các món đã được AI gợi ý
router.get('/pantry/history', JWT, scanController.getRecipeHistory);

// Xóa toàn bộ lịch sử
router.delete('/pantry/history', JWT, scanController.clearRecipeHistory);

// Xóa nhiều mục lịch sử đã chọn (Nhận mảng ID từ body)
router.post('/pantry/history/delete', JWT, scanController.deleteHistoryItems);

module.exports = router;