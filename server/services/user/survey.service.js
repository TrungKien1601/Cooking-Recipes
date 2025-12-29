const { GoogleGenerativeAI } = require("@google/generative-ai");
const User = require('../../models/User'); 
const UserProfile = require('../../models/UserProfile');
const tagsData = require('../../models/Tag'); 
const { generateMealPlanPrompt } = require('../../utils/SurveyPrompt');

require("dotenv").config();

// Config AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ 
    model: "gemini-2.5-flash", 
    generationConfig: { responseMimeType: "application/json" }
});

// --- HELPER FUNCTIONS (Private) ---
// Các hàm này chỉ dùng nội bộ trong file này nên để bên ngoài Object cho gọn

const parseNumber = (value) => {
    if (typeof value === 'number') return value;
    if (!value) return 0;
    const number = parseFloat(value.toString().replace(/[^0-9.]/g, ''));
    return isNaN(number) ? 0 : number;
};

const cleanJsonString = (jsonString) => {
    if (!jsonString) return null;
    let cleaned = jsonString.replace(/^```json\s*/, '').replace(/\s*```$/, '');
    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
};

const calculateHealthMetrics = (weight, height, age, gender, goal) => {
    const w = Number(weight);
    const h_cm = Number(height);
    const h_m = h_cm / 100;
    const a = Number(age);
    const genderLower = gender ? gender.toLowerCase() : 'male'; 

    // BMI
    const bmi = (w / (h_m * h_m)).toFixed(1);
    let bmiStatus = "Bình thường";
    if (bmi < 18.5) bmiStatus = "Thiếu cân";
    else if (bmi >= 23) bmiStatus = "Thừa cân"; 
    
    // BMR (Mifflin-St Jeor)
    let bmr = 10 * w + 6.25 * h_cm - 5 * a;
    if (genderLower === 'male' || genderLower === 'nam') bmr += 5;
    else bmr -= 161;

    // TDEE
    let tdee = Math.round(bmr * 1.375);
    
    // Adjust by Goal
    if (goal === 'Giảm cân') tdee -= 500;
    else if (['Tăng cân', 'Tăng cân lành mạnh', 'Tăng cơ'].includes(goal)) tdee += 500;

    if (tdee < 1200) tdee = 1200; 

    return { bmi, bmiStatus, targetCalories: tdee, numAge: a };
};

// ==========================================
// SURVEY SERVICE OBJECT
// ==========================================
const SurveyService = {

    // 1. Lấy Options cho form khảo sát
    async getSurveyOptions() {
        const allTags = await tagsData.find({}).lean();

        // Map từ Tiếng Việt (trong DB) -> Key Tiếng Anh (cho Frontend dùng)
        const typeMapping = {
            'Tình trạng sức khoẻ': 'healthConditions',
            'Chế độ ăn kiêng': 'diets',
            'Thói quen': 'habits',
            'Mục tiêu dinh dưỡng': 'goals', // Đổi nutritionGoal thành goals cho gọn
            'Dị ứng': 'exclusions'
        };

        const groupedOptions = allTags.reduce((acc, item) => {
            // Kiểm tra xem type của tag có nằm trong danh sách cần lấy không
            const groupKey = typeMapping[item.type];

            if (groupKey) {
                if (!acc[groupKey]) acc[groupKey] = [];
                acc[groupKey].push(item.name);
            }
            return acc;
        }, {});

        return groupedOptions;
    },

    // 2. Xử lý logic Submit Survey
    async processSurveySubmission(userId, surveyData) {
        const { weight, height, age, gender, goal, habits, healthConditions, diets, food_restrictions, exclusions } = surveyData;

        const user = await User.findById(userId);
        if (!user) throw new Error("User không tồn tại trong DB");

        // A. Tính toán chỉ số sức khỏe
        const { bmi, bmiStatus, targetCalories, numAge } = calculateHealthMetrics(weight, height, age, gender, goal);

        // B. Tạo Prompt & Gọi AI
        const prompt = generateMealPlanPrompt({
            gender, age: numAge, bmi, bmiStatus, goal, targetCalories,
            healthConditions, habits, diets, exclusions,
            otherRestrictions: food_restrictions 
        });

        const result = await model.generateContent(prompt);
        const responseText = result.response.text();
        
        let aiData;
        try {
            const cleanText = cleanJsonString(responseText);
            aiData = JSON.parse(cleanText);
        } catch (parseError) {
            console.error("🔥 JSON Parse Error:", responseText);
            throw new Error("AI_ERROR"); // Throw code lỗi đặc biệt để controller bắt
        }

        // C. Chuẩn bị dữ liệu lưu DB
        const finalCalories = parseNumber(aiData.nutritionTargets?.calories) || targetCalories;

        const safeNutrition = {
            calories: finalCalories,
            protein: parseNumber(aiData.nutritionTargets?.protein) || Math.round((finalCalories * 0.3) / 4),
            carbs: parseNumber(aiData.nutritionTargets?.carbs) || Math.round((finalCalories * 0.35) / 4),
            fat: parseNumber(aiData.nutritionTargets?.fat) || Math.round((finalCalories * 0.35) / 9),
            bmi,
            bmiStatus,
            tdee: targetCalories
        };

        const profileData = {
            user: user._id,
            weight: { value: Number(weight), unit: 'kg' },
            height: { value: Number(height), unit: 'cm' },
            age: Number(age),
            gender, goal, habits, healthConditions, diets, exclusions,
            allergies: food_restrictions ? [food_restrictions] : [], 
            nutritionTargets: safeNutrition,
            ai_recommendations: aiData.recommendations || [],
            ai_foods_to_avoid: aiData.foodsToAvoid || [],
            ai_meal_suggestions: (aiData.mealSuggestions || []).map(meal => ({
                session: meal.session,
                name: meal.name,
                calories: parseNumber(meal.calories),
                time: meal.time,
                description: meal.description,
                ingredients: meal.ingredients || [],
                instructions: meal.instructions || [],
                macros: meal.macros || { carbs: 0, fat: 0, protein: 0 }
            })),
        };

        // D. Lưu vào DB
        user.isSurveyDone = true; 
        await Promise.all([
            UserProfile.findOneAndUpdate(
                { user: user._id },
                { $set: profileData },
                { new: true, upsert: true, setDefaultsOnInsert: true }
            ),
            user.save()
        ]);

        console.log("✅ Submit Survey thành công cho:", user.email);

        // E. Trả về data cho Controller
        return {
            nutrition: safeNutrition,
            recommendations: aiData.recommendations,
            foodsToAvoid: aiData.foodsToAvoid,
            mealSuggestions: aiData.mealSuggestions
        };
    }
};

module.exports = SurveyService;