const authService = require('../../services/user/auth.service');

// --- Helpers Utilities ---
const getUserId = (req) => req.decoded?._id || req.user?._id;

const normalizeFilePath = (file) => {
    if (!file) return undefined;
    let path = file.path.replace(/\\/g, "/");
    return path.startsWith('public/') ? path.replace('public/', '') : path;
};

// Helper xử lý lỗi tập trung (giữ logic thông minh của bạn)
const handleError = (res, error) => {
    console.error("Auth Controller Error:", error);
    
    let statusCode = 500;
    const msg = error.message || "";

    // Map các lỗi thường gặp sang HTTP Status Code chuẩn
    if (msg.includes("không đúng") || msg.includes("Token") || msg.includes("Unauthorized")) statusCode = 401;
    else if (msg.includes("tồn tại") || msg.includes("Thiếu") || msg.includes("không hợp lệ")) statusCode = 400;
    else if (msg.includes("không tìm thấy") || msg.includes("not found")) statusCode = 404;

    return res.status(statusCode).json({
        success: false,
        message: msg || "Lỗi hệ thống"
    });
};

const authController = {

    // 1. AUTHENTICATION (LOGIN/REGISTER)
    googleLogin: async (req, res) => {
        try {
            const { idToken } = req.body;
            if (!idToken) return res.status(400).json({ success: false, message: "Vui lòng cung cấp Google ID Token" });

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
            return handleError(res, error);
        }
    },

    loginUser: async (req, res) => {
        try {
            const { email, password } = req.body;
            if (!email || !password) return res.status(400).json({ success: false, message: "Vui lòng nhập email và mật khẩu" });

            const result = await authService.processLogin(email, password);

            return res.status(200).json({
                success: true,
                message: "Đăng nhập thành công!",
                token: result.token,
                userId: result.userId,
                isSurveyDone: result.isSurveyDone,
                data: result.data
            });
        } catch (error) {
            return handleError(res, error);
        }
    },

    // 2. OTP & REGISTRATION FLOW
    sendOtp: async (req, res) => {
        try {
            const { email, type } = req.body;
            if (!email) return res.status(400).json({ success: false, message: "Thiếu Email" });

            const result = await authService.sendOtpCode(email, type);
            // Service trả về { success: true, message: ... }
            return res.status(200).json(result); 
        } catch (error) {
            return handleError(res, error);
        }
    },

    verifyAndRegister: async (req, res) => {
        try {
            // body: { email, otp, password, ... }
            const { token, userData, userId } = await authService.verifyAndRegisterUser(req.body);

            return res.status(201).json({
                success: true,
                message: "Đăng ký thành công!",
                token,
                userId,
                data: userData
            });
        } catch (error) {
            return handleError(res, error);
        }
    },

    // 3. PASSWORD MANAGEMENT
    resetPasswordWithOTP: async (req, res) => {
        try {
            const { email, otp, newPassword } = req.body;
            if (!email || !otp || !newPassword) {
                return res.status(400).json({ success: false, message: "Vui lòng nhập đủ thông tin" });
            }

            const result = await authService.processPasswordReset(email, otp, newPassword);
            
            return res.status(200).json({
                success: true,
                message: "Đổi mật khẩu thành công",
                token: result.token 
            });
        } catch (error) {
            return handleError(res, error);
        }
    },

    // 4. USER PROFILE
    getProfile: async (req, res) => {
        try {
            // Ưu tiên lấy ID từ Token (chính chủ), fallback sang query (cho Admin view)
            let identifier = getUserId(req);
            if (!identifier && req.query.userId) {
                identifier = req.query.userId;
            }
            
            if (!identifier) return res.status(401).json({ success: false, message: "Không xác định được người dùng" });

            const fullData = await authService.getUserProfile(identifier, req);
            return res.status(200).json({ success: true, data: fullData });
        } catch (error) {
            return handleError(res, error);
        }
    },

    updateProfile: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });

            const updatedProfile = await authService.updateUserProfile(userId, req.body);
            return res.status(200).json({ 
                success: true, 
                message: "Cập nhật thành công",
                data: updatedProfile 
            });
        } catch (error) {
            return handleError(res, error);
        }
    },

    uploadAvatar: async (req, res) => {
        try {
            if (!req.file) return res.status(400).json({ success: false, message: 'Không có file được upload' });
            
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });

            // Sử dụng helper để chuẩn hóa path
            const imagePath = normalizeFilePath(req.file);
            
            const updatedUser = await authService.updateAvatar(userId, imagePath);

            return res.status(200).json({
                success: true,
                message: 'Cập nhật ảnh đại diện thành công',
                filePath: imagePath,
                user: updatedUser
            });
        } catch (error) {
            return handleError(res, error);
        }
    },

    // 5. FEATURES
    getMealSuggestions: async (req, res) => {
        try {
            let identifier = getUserId(req);
            if (!identifier && req.query.userId) identifier = req.query.userId;

            if (!identifier) return res.status(400).json({ success: false, message: "Thiếu UserId" });

            const data = await authService.getMealPlanData(identifier);
            return res.status(200).json({ success: true, data });
        } catch (error) {
            return handleError(res, error);
        }
    }
};

module.exports = authController;