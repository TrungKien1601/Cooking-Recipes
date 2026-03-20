const express = require('express');
const router = express.Router();

// --- IMPORTS ---
const authController = require('../../controllers/user/auth.controller');
// Import Controller Khảo sát mới làm
const surveyController = require('../../controllers/user/survey.controller'); 
const { uploadImage } = require('../../config/multer'); 
const JwtUtil = require('../../utils/JwtUtils'); 

// --- MIDDLEWARE ---
const protect = JwtUtil.checkToken; 

// ============================================================
// A. PUBLIC ROUTES (Không cần Token)
// ============================================================

// 1. Auth & Registration
router.post('/google-login', authController.googleLogin);
router.post('/login', authController.loginUser);
router.post('/register', authController.verifyAndRegister); 

// 2. OTP & Password Recovery
router.post('/send-otp', authController.sendOtp);
router.post('/reset-password', authController.resetPasswordWithOTP); 

// 3. Static Data (Lấy danh sách tags cho form khảo sát)
// Route này khớp với hàm getSurveyOptions bên controller
router.get('/survey-options', surveyController.getSurveyOptions);

// ============================================================
// B. PROTECTED ROUTES (Yêu cầu Token)
// ============================================================

// 1. User Profile 
router.get('/profile', protect, authController.getProfile);     
router.put('/profile', protect, authController.updateProfile);  

// 2. Features - SURVEY & MEAL PLAN
// Route này khớp với hàm submitSurvey bên controller (trả về kết quả lọc + nutrition)
router.post('/survey', protect, surveyController.submitSurvey);         

// Lưu ý: Hàm getMealSuggestions này đang nằm ở authController (theo code cũ của bạn). 
// Nếu bạn muốn chuyển nó sang surveyController thì sửa lại tham chiếu nhé.
router.get('/meal-suggestions', protect, authController.getMealSuggestions); 

// 3. Avatar Upload (Giữ nguyên logic xử lý lỗi Multer tại chỗ của bạn)
router.post('/avatar', 
    protect, 
    (req, res, next) => {
        // Gọi hàm single('image') từ cấu hình multer
        const upload = uploadImage.single('image');
        
        upload(req, res, (err) => {
            if (err) {
                // Xử lý các lỗi cụ thể của Multer
                if (err.code === 'LIMIT_FILE_SIZE') {
                    return res.status(400).json({ success: false, message: "Ảnh quá lớn (Max 5MB)!" });
                }
                return res.status(400).json({ 
                    success: false, 
                    message: "Lỗi upload: " + err.message 
                });
            }
            // Nếu không lỗi thì sang controller xử lý lưu vào DB
            next();
        });
    },
    authController.uploadAvatar 
);

module.exports = router;