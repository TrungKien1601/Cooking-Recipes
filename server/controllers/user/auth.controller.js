const authService = require('../../services/user/auth.service');

// Helper: Lấy User ID an toàn từ Request (Do JwtUtils lưu vào req.decoded)
const getUserIdFromReq = (req) => {
    // Ưu tiên lấy từ req.decoded (theo JwtUtils của bạn)
    if (req.decoded && req.decoded._id) return req.decoded._id;
    // Fallback nếu middleware khác gán vào req.user
    if (req.user && req.user._id) return req.user._id;
    if (req.user && req.user.id) return req.user.id;
    return null;
};

// ============================================================
// 1. API ĐĂNG NHẬP GOOGLE
// ============================================================
exports.googleLogin = async (req, res) => {
    try {
        const { idToken } = req.body; 
        
        if (!idToken) {
            return res.status(400).json({ 
                success: false, 
                message: "Vui lòng cung cấp Google ID Token" 
            });
        }
        
        const result = await authService.processGoogleLogin(idToken);

        return res.status(200).json({
            success: true,
            message: "Đăng nhập Google thành công",
            token: result.token,
            userId: result.userId,
            isSurveyDone: result.isSurveyDone,
            data: result.userData
        });

    } catch (error) {
        console.error("Lỗi Google Login Controller:", error);
        const isAuthError = error.message.includes("Token") || error.message.includes("hết hạn");
        const statusCode = isAuthError ? 401 : 500;

        return res.status(statusCode).json({ 
            success: false, 
            message: error.message || "Lỗi hệ thống khi đăng nhập Google" 
        });
    }
};

// ============================================================
// 2. API ĐĂNG NHẬP EMAIL/PASSWORD
// ============================================================
exports.loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        const result = await authService.processLogin(email, password);
        
        res.status(200).json({
            success: true,
            message: "Đăng nhập thành công!",
            token: result.token,
            userId: result.userId,
            isSurveyDone: result.isSurveyDone, 
            data: result.data
        });

    } catch (error) {
        console.error("Lỗi Login:", error.message);
        const status = error.message.includes("mật khẩu không đúng") ? 401 : 500;
        res.status(status).json({ message: error.message });
    }
};

// ============================================================
// 3. API GỬI OTP
// ============================================================
exports.sendOtp = async (req, res) => {
    try {
        const { email, type } = req.body;
        if (!email) return res.status(400).json({ message: "Thiếu Email" });

        const result = await authService.sendOtpCode(email, type);
        return res.status(200).json(result);

    } catch (error) {
        console.error("Lỗi Send OTP:", error.message);
        const status = error.message.includes("đã tồn tại") || error.message.includes("chưa đăng ký") ? 400 : 500;
        res.status(status).json({ message: error.message });
    }
};

// ============================================================
// 4. XÁC THỰC OTP VÀ ĐĂNG KÝ
// ============================================================
exports.verifyAndRegister = async (req, res) => {
    try {
        const { token, userData, userId } = await authService.verifyAndRegisterUser(req.body);

        res.status(201).json({
            success: true,
            message: "Đăng ký thành công!",
            token: token,
            data: userData,
            userId: userId
        });

    } catch (error) {
        console.error("Lỗi đăng ký:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// ============================================================
// 5. ĐỔI MẬT KHẨU
// ============================================================
exports.resetPasswordWithOTP = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;
        const result = await authService.processPasswordReset(email, otp, newPassword);

        res.status(200).json({ success: true, message: "Đổi mật khẩu thành công", token: result.token });

    } catch (error) {
        console.error("Lỗi Đổi Mật Khẩu:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// ============================================================
// 6. LẤY THÔNG TIN PROFILE
// ============================================================
exports.getProfile = async (req, res) => {
    try {
        // SỬA: Dùng hàm helper để lấy ID chính xác từ req.decoded
        let identifier = getUserIdFromReq(req) || req.query.userId;

        if (!identifier) {
            return res.status(400).json({ success: false, message: "Không tìm thấy User ID" });
        }

        const fullData = await authService.getUserProfile(identifier, req);
        
        res.status(200).json({ success: true, data: fullData });

    } catch (error) {
        console.error("❌ LỖI NGHIÊM TRỌNG TẠI GET-PROFILE:", error.message);
        const status = error.message.includes("Không tìm thấy User") ? 404 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};

// ============================================================
// 7. CẬP NHẬT PROFILE
// ============================================================
exports.updateProfile = async (req, res) => {
    try {
        // SỬA: Lấy ID từ req.decoded
        const userId = getUserIdFromReq(req) || req.body.userId;
        
        if (!userId) return res.status(401).json({ message: "Không xác định được User để cập nhật" });
        
        const updatedProfile = await authService.updateUserProfile(userId, req.body);

        res.status(200).json({ success: true, message: "Cập nhật thành công", data: updatedProfile });
        
    } catch (error) {
        console.error("❌ LỖI UPDATE PROFILE:", error.message);
        res.status(500).json({ success: false, message: "Lỗi: " + error.message });
    }
};

// ============================================================
// 8. LẤY GỢI Ý MÓN ĂN 
// ============================================================
exports.getMealSuggestions = async (req, res) => {
    try {
        // SỬA: Lấy ID từ req.decoded
        const userIdFromToken = getUserIdFromReq(req);
        const identifier = req.query.userId || userIdFromToken || req.params.userId; 

        if (!identifier) return res.status(400).json({ message: "Thiếu UserId" });

        const data = await authService.getMealPlanData(identifier);

        res.status(200).json({ success: true, data: data });

    } catch (error) {
        console.error("❌ Lỗi getMealSuggestions:", error.message);
        const status = error.message.includes("không tồn tại") || error.message.includes("Chưa có hồ sơ") ? 404 : 500;
        res.status(status).json({ message: error.message });
    }
};

// ============================================================
// 9. UPLOAD AVATAR
// ============================================================
exports.uploadAvatar = async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Không có file' });

        // SỬA: Lấy ID từ req.decoded
        const userId = getUserIdFromReq(req);
        
        if (!userId) {
            return res.status(401).json({ success: false, message: 'Unauthorized: Token không hợp lệ' });
        }

        const imagePath = `uploads/${req.file.filename}`;
        
        const updatedUser = await authService.updateAvatar(userId, imagePath);

        return res.status(200).json({
            success: true,
            message: 'Cập nhật ảnh thành công',
            filePath: imagePath, 
            user: updatedUser
        });

    } catch (error) {
        console.error("Upload Error:", error.message);
        return res.status(500).json({ success: false, message: 'Lỗi server' });
    }
};