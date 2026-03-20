const express = require('express');
const router = express.Router();
const RecipeController = require('../../controllers/admin/recipe.controller');

const JwtUtil = require('../../utils/JwtUtils');
const { uploadMixed } = require('../../config/multer');

// Lấy danh sách
router.get('/', JwtUtil.checkToken, RecipeController.getRecipes);

// Tạo mới: Nhận file từ field 'image' (bắt buộc) và 'video' (tuỳ chọn)
router.post('/', JwtUtil.checkToken, uploadMixed.fields([
    { name: "image", maxCount: 10 }, 
    { name: "video", maxCount: 1 }
]), RecipeController.addNewRecipe);

// Cập nhật theo ID
router.put('/:id', JwtUtil.checkToken, uploadMixed.fields([
    { name: "image", maxCount: 10 }, 
    { name: "video", maxCount: 1 }
]), RecipeController.updateRecipe);

// Xoá theo ID
router.delete('/:id', JwtUtil.checkToken, RecipeController.deleteRecipe);

module.exports = router;