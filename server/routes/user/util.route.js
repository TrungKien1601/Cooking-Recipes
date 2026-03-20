// File: server/routes/user/util.route.js
const express = require('express');
const router = express.Router(); // <--- Sửa ở đây
const utilController = require('../../controllers/user/util.controller'); // Đảm bảo đường dẫn này trỏ đúng tới file controller của bạn

// Định nghĩa API
router.get('/search-image', utilController.searchImage);

module.exports = router;