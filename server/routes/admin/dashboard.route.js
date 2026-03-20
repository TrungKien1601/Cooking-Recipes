// routes/admin/dashboard.route.js
const express = require('express');
const router = express.Router();
const DashboardController = require('../../controllers/admin/dashboard.controller');
const JwtUtil = require('../../utils/JwtUtils'); // Import middleware check token

// Định nghĩa route: GET /api/dashboard/stats
// JwtUtil.checkToken: Đảm bảo chỉ người đã đăng nhập mới xem được
router.get('/stats', JwtUtil.checkToken, DashboardController.getStatisticalCounts);

router.get('/chart', JwtUtil.checkToken, DashboardController.getChartData);

module.exports = router;