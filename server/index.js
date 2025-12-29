// 1. IMPORT CÁC THƯ VIỆN LÕI (Third-party libraries)
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

// 2. IMPORT CÁC MODULE NỘI BỘ (Local modules)
const connectDB = require('./config/db');

// Import Routes
const userRoute = require('./routes/user/user.route');
const scanRoute = require('./routes/user/scan.route');
const recipeRoute = require('./routes/user/recipe.route');
const adminRoute = require('./routes/admin/index.js'); // Nên đặt biến cho đồng bộ

// 3. KHỞI TẠO APP & CONFIG
const app = express();
const PORT = process.env.PORT || 3000;

// 4. KẾT NỐI DATABASE & MODELS
connectDB();
// Pre-load models (để tránh lỗi MissingSchemaError khi dùng populate/ref)
require("./models/Role.js");
require('./models/User.js');

// 5. GLOBAL MIDDLEWARES (Chạy trước khi vào routes)
// Cấu hình CORS
app.use(cors({
    origin: 'http://localhost:4000',
    credentials: true,
}));

// Cấu hình Body Parser (Xử lý dữ liệu gửi lên)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Cấu hình Static Files (Công khai thư mục ảnh/video)
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));
app.use('/videos', express.static(path.join(__dirname, 'public/videos')));

// 6. ROUTES DEFINITION
// Admin Routes
app.use('/api/admin', adminRoute);

// User Routes
app.use('/api/auth', userRoute);
app.use('/api', scanRoute); // Lưu ý: route này hơi chung chung, nên là /api/scan nếu có thể
app.use('/api/recipes', recipeRoute);

// 7. START SERVER
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});