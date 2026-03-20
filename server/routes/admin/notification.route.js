const express = require('express');
const router = express.Router();
const NotiController = require('../../controllers/admin/notification.controller');
const JwtUtil = require('../../utils/JwtUtils');

// API lấy danh sách: GET /api/admin/notification
router.get('/', JwtUtil.checkToken, NotiController.getList);

// API đánh dấu đã đọc: PUT /api/admin/notification/read
router.put('/read', JwtUtil.checkToken, NotiController.markRead);

module.exports = router;