const { GoogleGenerativeAI } = require("@google/generative-ai");
const User = require('../../models/User'); 
const UserProfile = require('../../models/UserProfile');
const tagsData = require('../../models/Tag'); 
const Recipe = require('../../models/Recipe'); 
const { generateMealPlanPrompt } = require('../../utils/SurveyPrompt');

require("dotenv").config();

// --- CONFIG & HELPERS ---
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ 
    model: "gemini-2.5-flash", 
    generationConfig: { responseMimeType: "application/json" }
});

const parseNumber = (value) => {
    if (typeof value === 'number') return value;
    if (!value) return 0;
    // Xử lý trường hợp "20-30g" -> lấy trung bình hoặc số đầu
    const match = value.toString().match(/(\d+(\.\d+)?)/);
    return match ? parseFloat(match[0]) : 0;
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

const calculateMetrics = (weight, height, age, gender, goal) => {
    const w = Number(weight);
    const h = Number(height) / 100;
    const a = Number(age);
    
    // Tính BMI
    const bmi = Number((w / (h * h)).toFixed(1));
    let bmiStatus = "Bình thường";
    if (bmi < 18.5) bmiStatus = "Thiếu cân";
    else if (bmi < 23) bmiStatus = "Bình thường";
    else if (bmi < 25) bmiStatus = "Thừa cân";
    else if (bmi < 30) bmiStatus = "Béo phì độ I";
    else bmiStatus = "Béo phì độ II";

    // Tính BMR (Mifflin-St Jeor)
    let bmr = 10 * w + 6.25 * (h * 100) - 5 * a;
    bmr += (gender?.toLowerCase() === 'nam' || gender?.toLowerCase() === 'male') ? 5 : -161;

    // Tính TDEE & Target Calories
    let tdee = Math.round(bmr * 1.375); // Mặc định vận động nhẹ
    let targetCalories = tdee;
    
    if (goal === 'Giảm cân') targetCalories = Math.round(tdee * 0.85);
    else if (goal && goal.includes('Tăng')) targetCalories = Math.round(tdee * 1.10);

    return { bmi, bmiStatus, targetCalories: Math.max(1200, targetCalories), numAge: a };
};

const SurveyService = {
    async getSurveyOptions() {
        const allTags = await tagsData.find({}).lean();
        const typeMapping = {
            'Tình trạng sức khoẻ': 'healthConditions',
            'Chế độ ăn kiêng': 'diets',
            'Thói quen': 'habits',
            'Mục tiêu dinh dưỡng': 'goals',
            'Dị ứng': 'exclusions'
        };

        return allTags.reduce((acc, item) => {
            const key = typeMapping[item.type];
            if (key) {
                if (!acc[key]) acc[key] = [];
                acc[key].push(item.name);
            }
            return acc;
        }, {});
    },

    async processSurveySubmission(userId, surveyData) {
        const user = await User.findById(userId);
        if (!user) throw new Error("User not found");

        const { weight, height, age, gender, goal, habits, healthConditions, diets, food_restrictions, exclusions } = surveyData;

        // 1. Tính toán Metrics
        const { bmi, bmiStatus, targetCalories, numAge } = calculateMetrics(weight, height, age, gender, goal);

        // 2. Gọi AI
        const prompt = generateMealPlanPrompt({
            gender, age: numAge, bmi, bmiStatus, goal, targetCalories,
            healthConditions, habits, diets, exclusions,
            otherRestrictions: food_restrictions
        });

        let aiData;
        try {
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            aiData = JSON.parse(cleanJsonString(text));
        } catch (e) {
            console.error("AI Generation Error:", e);
            // Fallback data
            aiData = { 
                nutritionTargets: { calories: targetCalories },
                recommendations: ["Hãy ăn uống cân bằng và tập thể dục đều đặn."],
                foodsToAvoid: [],
                mealSuggestions: []
            };
        }

        // 3. Chuẩn hóa dữ liệu lưu DB
        const cal = parseNumber(aiData.nutritionTargets?.calories) || targetCalories;
        const nutritionTargets = {
            calories: cal,
            protein: parseNumber(aiData.nutritionTargets?.protein) || Math.round((cal * 0.3) / 4),
            carbs: parseNumber(aiData.nutritionTargets?.carbs) || Math.round((cal * 0.35) / 4),
            fat: parseNumber(aiData.nutritionTargets?.fat) || Math.round((cal * 0.35) / 9),
            bmi, bmiStatus, tdee: targetCalories
        };

        const updateData = {
            weight: { value: Number(weight), unit: 'kg' },
            height: { value: Number(height), unit: 'cm' },
            age: Number(age),
            gender, goal, habits, healthConditions, diets, exclusions,
            allergies: food_restrictions ? [food_restrictions] : [],
            nutritionTargets,
            ai_recommendations: aiData.recommendations || [],
            ai_foods_to_avoid: aiData.foodsToAvoid || [],
            ai_meal_suggestions: aiData.mealSuggestions || []
        };

        // 4. Lưu DB Profile và User Status
        await Promise.all([
            UserProfile.findOneAndUpdate(
                { user: userId }, 
                { $set: updateData }, 
                { new: true, upsert: true, setDefaultsOnInsert: true }
            ),
            User.findByIdAndUpdate(userId, { isSurveyDone: true })
        ]);
        let filteredRecipes = [];

        try {
            const rawBlacklist = [
                ...(exclusions || []), 
                food_restrictions, 
                // Chỉ thêm từ AI nếu nó ngắn gọn (dưới 20 ký tự) để tránh câu dài gây lỗi query
                ...(aiData.foodsToAvoid || []).filter(t => t && t.length < 20) 
            ];

            // Làm sạch: chữ thường, bỏ khoảng trắng thừa
            const cleanBlacklist = rawBlacklist
                .flat()
                .filter(item => item && typeof item === 'string')
                .map(item => item.toLowerCase().trim());

            // B. Tạo Query
            const query = {};

            if (cleanBlacklist.length > 0) {
                query["ingredients.name"] = { $nin: cleanBlacklist };
                
                // Mở rộng: Lọc cả Title nếu cần (Optional)
                query["title"] = { $not: { $in: cleanBlacklist.map(w => new RegExp(w, "i")) } };
            }
            filteredRecipes = await Recipe.find(query)
                .select('title image description ingredients nutrition') 
                .limit(20) 
                .lean();

            // Nếu lọc quá gắt khiến không còn món nào, lấy random 5 món healthy làm fallback
            if (filteredRecipes.length === 0) {
                filteredRecipes = await Recipe.find({})
                    .limit(5)
                    .lean();
            }

        } catch (error) {
            console.error("Lỗi khi lọc công thức:", error);
            // Không throw lỗi để app không crash, trả về mảng rỗng
            filteredRecipes = []; 
        }

        // 6. Return kết quả về Controller
        return {
            nutrition: nutritionTargets,
            recommendations: updateData.ai_recommendations,
            foodsToAvoid: updateData.ai_foods_to_avoid,
            mealSuggestions: updateData.ai_meal_suggestions,
            // Dữ liệu quan trọng nhất để hiển thị bên App
            filteredRecipes: filteredRecipes 
        };
    }
};

module.exports = SurveyService;