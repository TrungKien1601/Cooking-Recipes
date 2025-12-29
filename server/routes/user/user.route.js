const express = require('express');
const router = express.Router();

// 1. Imports Controllers
const authController = require('../../controllers/user/auth.controller');
const surveyController = require('../../controllers/user/survey.controller'); 
// 2. Imports Configs & Middleware
const uploadPicture = require('../../config/multer');
const JwtUtil = require('../../utils/JwtUtils'); 

// Định nghĩa Middleware verify token
const JWT = JwtUtil.checkToken;

// ==============================
// A. ROUTES PUBLIC (Không cần Login)
// ==============================

// 1. Auth & Registration
router.post('/google-login', authController.googleLogin);
router.post('/login', authController.loginUser);
router.post('/register', authController.verifyAndRegister); // Đăng ký (đã bao gồm verify OTP)

// 2. OTP & Password Recovery
router.post('/send-otp', authController.sendOtp);
router.post('/reset-password-otp', authController.resetPasswordWithOTP);

// 3. Survey Data (Load options cho form)
router.get('/survey-options', surveyController.getSurveyOptions);


// ==============================
// B. ROUTES PRIVATE (Cần Login - verifyToken)
// ==============================

// 1. Survey Action
router.post('/submit-survey', JWT, surveyController.submitSurvey);

// 2. User Profile & Meal Plan
router.get('/get-profile', JWT, authController.getProfile);
router.put('/update-profile', JWT, authController.updateProfile); 
router.get('/get-meal-suggestions', JWT, authController.getMealSuggestions);

// 3. Upload Avatar (Xử lý lỗi Multer chi tiết)
router.post('/upload-avatar', 
    JWT, // B1: Check token trước
    (req, res, next) => {
        // B2: Middleware xử lý upload file ảnh
        const upload = uploadPicture.single('image');
        
        upload(req, res, (err) => {
            if (err) {
                // Xử lý lỗi từ Multer (File quá lớn, sai định dạng...)
                return res.status(400).json({ 
                    success: false, 
                    message: "Lỗi upload ảnh: " + err.message 
                });
            }
            // Không lỗi -> Chuyển sang controller xử lý logic DB
            next();
        });
    },
    authController.uploadAvatar 
);

module.exports = router;