const express = require('express');
const router = express.Router();
const AdminController = require('../../controllers/admin/admin.controller')

const JwtUtil = require('../../utils/JwtUtils');
const { uploadImage } = require('../../config/multer');

//Đăng nhập
router.post('/signin', AdminController.sigin);

router.get('/token', JwtUtil.checkToken, AdminController.checkToken);


// Quên mật khẩu
router.post('/send-otp', AdminController.sentOtp);

router.post('/verify-otp', AdminController.verifyOtp);

router.put('/reset-password', AdminController.resetPassword);


//User-Function
router.get('/auth/me', JwtUtil.checkToken, AdminController.authMe);

router.put('/update-user', JwtUtil.checkToken, AdminController.updateUser);


//xử lý hình ảnh
router.put('/upload-avatar', JwtUtil.checkToken, uploadImage.single('image'), AdminController.uploadAvatar);


module.exports = router;