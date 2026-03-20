const express = require('express');
const router = express.Router();
const PantryController = require('../../controllers/admin/pantry.controller');

const JwtUtil = require('../../utils/JwtUtils');

// 1. Route lấy danh sách thống kê (User | Email | Tổng số món)
// Dùng cho bảng chính bên ngoài
router.get('/', JwtUtil.checkToken, PantryController.getPantryStats);

// 2. Route xem chi tiết các món của 1 user cụ thể
// Frontend gọi API này khi bấm vào một dòng user
router.get('/user/:userId', JwtUtil.checkToken, PantryController.getPantryDetailsByUser);

// 3. Route xoá 1 món đồ cụ thể theo ID món
router.delete('/:id', JwtUtil.checkToken, PantryController.deletePantryItem);

module.exports = router;