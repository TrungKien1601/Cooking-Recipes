const SurveyService = require('../../services/user/survey.service');

// --- Helpers Utilities ---
const getUserId = (req) => req.decoded?._id || req.user?._id || req.user?.id;

// Helper xử lý lỗi tập trung
const handleError = (res, error) => {
    console.error("❌ Survey Controller Error:", error);

    let statusCode = 500;
    const msg = error.message || "Lỗi hệ thống";

    // Map lỗi sang HTTP Status Code
    if (msg === "AI_ERROR") statusCode = 502; 
    else if (msg.includes("Unauthorized") || msg.includes("Phiên đăng nhập")) statusCode = 401;
    else if (msg.includes("User not found")) statusCode = 404;
    else if (msg.includes("Vui lòng") || msg.includes("không thực tế") || msg.includes("số dương")) statusCode = 400;

    return res.status(statusCode).json({
        success: false,
        message: msg
    });
};

const surveyController = {
    getSurveyOptions: async (req, res) => {
        try {
            const groupedOptions = await SurveyService.getSurveyOptions();
            
            const data = groupedOptions || {
                healthConditions: [], habits: [], goals: [], diets: [], exclusions: []
            };

            return res.status(200).json({ 
                success: true, 
                data: data 
            });
        } catch (error) {
            return handleError(res, error);
        }
    },
    submitSurvey: async (req, res) => {
        try {
            // 1. CHECK AUTH
            const userId = getUserId(req);
            if (!userId) throw new Error("Unauthorized: Phiên đăng nhập hết hạn.");
            console.log(`📥 User ${userId} đang submit Survey...`);
            let { weight, height, age, gender, goal, habits, diets, food_restrictions, exclusions, healthConditions } = req.body;

            // Check required fields
            if (!weight || !height || !age || !gender || !goal) {
                throw new Error("Vui lòng điền đầy đủ: Cân nặng, Chiều cao, Tuổi, Giới tính, Mục tiêu.");
            }
            const w = Number(weight);
            const h = Number(height);
            const a = Number(age);

            // Check số dương
            if (isNaN(w) || w <= 0 || isNaN(h) || h <= 0 || isNaN(a) || a <= 0) {
                throw new Error("Chỉ số cơ thể (Cân nặng, Chiều cao, Tuổi) phải là số dương!");
            }

            if (h > 300 || w > 500 || a > 120) {
                throw new Error("Thông tin chỉ số cơ thể không thực tế. Vui lòng kiểm tra lại.");
            }

            // 3. CLEAN DATA OBJECT
            const cleanData = {
                ...req.body,
                weight: w,
                height: h,
                age: a,
                gender: gender.toString().trim(),
                goal: goal.toString().trim(),
                food_restrictions: food_restrictions ? food_restrictions.toString().trim() : "",
                habits: Array.isArray(habits) ? habits : [],
                diets: Array.isArray(diets) ? diets : [],
                
                // Nếu không có dòng này, Service sẽ nhận undefined và lọc không chuẩn
                exclusions: Array.isArray(exclusions) ? exclusions : [], 
                healthConditions: Array.isArray(healthConditions) ? healthConditions : [],
            };

            const resultData = await SurveyService.processSurveySubmission(userId, cleanData);

            // Log nhẹ để debug xem có món ăn trả về không
            console.log(`✅ Submit thành công. Đã lọc được: ${resultData.filteredRecipes?.length || 0} công thức.`);

            return res.status(200).json({
                success: true,
                message: "Phân tích thành công!",
                data: resultData 
            });

        } catch (error) {
            return handleError(res, error);
        }
    }
};

module.exports = surveyController;