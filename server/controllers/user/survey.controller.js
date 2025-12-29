const SurveyService = require('../../services/user/survey.service');

// --- HELPER: Lấy User ID an toàn (Khớp với JwtUtils) ---
const getUserId = (req) => {
    // Ưu tiên lấy từ req.decoded (Do JwtUtils gán vào đây)
    if (req.decoded && req.decoded._id) return req.decoded._id;
    // Fallback nếu có middleware khác gán vào req.user
    if (req.user && req.user._id) return req.user._id;
    if (req.user && req.user.id) return req.user.id;
    return null;
};

// ==========================================
// 1. API: Lấy danh sách options (Tags)
// ==========================================
exports.getSurveyOptions = async (req, res) => {
    try {
        const groupedOptions = await SurveyService.getSurveyOptions();
        
        if (!groupedOptions || Object.keys(groupedOptions).length === 0) {
            return res.status(200).json({ 
                success: true, 
                message: "Chưa có dữ liệu tags",
                data: {} 
            });
        }

        res.status(200).json({ success: true, data: groupedOptions });
    } catch (error) {
        console.error("🔥 Lỗi lấy options:", error);
        res.status(500).json({ message: "Lỗi Server khi lấy Options" });
    }
};

// ==========================================
// 2. API: Gửi form khảo sát & Nhận Meal Plan
// ==========================================
exports.submitSurvey = async (req, res) => {
    try {
        // 1. SECURITY CHECK: Sửa lại cách lấy ID
        const userId = getUserId(req);

        if (!userId) {
            return res.status(401).json({ message: "Vui lòng đăng nhập để thực hiện chức năng này!" });
        }

        const { weight, height, age, gender, goal } = req.body;

        // 2. BASIC VALIDATION
        if (!weight || !height || !age || !gender || !goal) {
            return res.status(400).json({ message: "Vui lòng điền đầy đủ thông tin cơ bản (Cân nặng, Chiều cao, Tuổi...)" });
        }

        if (Number(weight) <= 0 || Number(height) <= 0 || Number(age) <= 0) {
            return res.status(400).json({ message: "Thông tin chỉ số cơ thể không hợp lệ!" });
        }

        console.log(`📥 User ${userId} đang request Survey & Gemini...`);

        // 3. Gọi Service xử lý
        const resultData = await SurveyService.processSurveySubmission(userId, req.body);

        res.status(200).json({
            success: true,
            message: "Tạo kế hoạch dinh dưỡng thành công!",
            data: resultData
        });

    } catch (error) {
        console.error("❌ ERROR submitSurvey:", error.message);
        
        // 4. Xử lý lỗi cụ thể
        if (error.message === "AI_ERROR") {
             return res.status(502).json({ 
                 message: "Hệ thống AI đang quá tải hoặc gặp sự cố. Vui lòng thử lại sau ít phút." 
             });
        }
        
        if (error.message.includes("User không tồn tại")) {
            return res.status(404).json({ message: "Không tìm thấy thông tin người dùng." });
        }
        
        res.status(500).json({ message: "Lỗi Server nội bộ." });
    }
};