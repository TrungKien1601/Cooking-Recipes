// File: routes/admin/index.js
const express = require('express');
const router = express.Router();

// Import các file route con
const adminAuthRoute = require('./admin.route');
const activityLogRoute = require('./activitylog.route');
const tagRoute = require('./tag.route');
const userProfileRoute = require('./userprofile.route');
const ingredientRoute = require('./ingredient.route');
const recipeRoute = require('./recipe.route');
const pantryRoute = require('./pantry.route');
const dashboardRoute = require('./dashboard.route');
const notificationRoute = require('./notification.route')

// Định nghĩa các đường dẫn con
// Lưu ý: Các file route con không cần sửa gì cả

// 1. Các route chung của admin (signin, auth/me,...) -> giữ nguyên gốc /api/admin/
router.use('/', adminAuthRoute); 

// 2. Các route resource khác -> nối thêm path tương ứng
router.use('/activity-log', activityLogRoute);
router.use('/tag', tagRoute);
router.use('/user-profile', userProfileRoute);
router.use('/ingredient', ingredientRoute);
router.use('/recipe', recipeRoute);
router.use('/pantry', pantryRoute);
router.use('/dashboard', dashboardRoute);
router.use('/notification', notificationRoute);

module.exports = router;