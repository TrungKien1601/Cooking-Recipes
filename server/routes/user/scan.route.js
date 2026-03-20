const express = require('express');
const router = express.Router();
const scanController = require('../../controllers/user/scan.controller'); 
const { uploadMixed } = require('../../config/multer'); 
const JwtUtil = require('../../utils/JwtUtils');
// Middleware check token
const JWT = JwtUtil.checkToken;
// Quét mã vạch
router.post('/scan/barcode', scanController.scanBarcode); 

// Quét ảnh nguyên liệu
router.post('/scan/image', uploadMixed.single('image'), scanController.scanImage);

// Gợi ý món ăn nhanh (Guest)
router.post('/scan/suggest-guest', scanController.suggestByIngredients);
router.post('/scan/upload-food', JWT, uploadMixed.single('image'), scanController.uploadFoodImage);
router.post('/scan/upload-multiple-foods', JWT, uploadMixed.array('images', 10), scanController.uploadMultipleFoods);
router.post('/pantry/suggest-chef', JWT, scanController.suggestRecipes); 
// Lấy lịch sử
router.get('/pantry/history', JWT, scanController.getRecipeHistory);

// Xóa toàn bộ lịch sử (Route tĩnh)
router.delete('/pantry/history', JWT, scanController.clearRecipeHistory);

// Xóa nhiều mục (Route tĩnh)
router.post('/pantry/history/delete', JWT, scanController.deleteHistoryItems);
// Lấy danh sách
router.get('/pantry', JWT, scanController.getPantry);

// Thêm món
router.post('/pantry', JWT, scanController.addToPantry);

// Sửa món (Route động có :id)
router.put('/pantry/:id', JWT, scanController.updateItem);

// Xóa món (Route động có :id) -> Đặt cuối cùng để an toàn
router.delete('/pantry/:id', JWT, scanController.deleteItem);

module.exports = router;