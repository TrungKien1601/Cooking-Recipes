// Hàm này nhận vào một object chứa data và trả về chuỗi Prompt hoàn chỉnh
const generateMealPlanPrompt = ({ 
    gender, 
    age, 
    bmi, 
    bmiStatus, 
    goal, 
    targetCalories, 
    healthConditions, 
    habits, 
    diets,
    exclusions,       
    otherRestrictions 
}) => {
    // 1. Xử lý logic format chuỗi
    const healthStr = Array.isArray(healthConditions) && healthConditions.length > 0 ? healthConditions.join(', ') : 'None';
    const habitStr = Array.isArray(habits) && habits.length > 0 ? habits.join(', ') : 'None';
    const dietStr = Array.isArray(diets) && diets.length > 0 ? diets.join(', ') : 'Normal';

    // 2. Xử lý chuỗi Dị ứng/Kiêng kị
    let restrictionList = [];
    if (Array.isArray(exclusions) && exclusions.length > 0) {
        restrictionList = [...exclusions];
    }
    if (otherRestrictions && otherRestrictions.trim() !== '') {
        restrictionList.push(otherRestrictions);
    }
    const restrictionStr = restrictionList.length > 0 ? restrictionList.join(', ') : 'None';

    // 3. Trả về Prompt (Đã tối ưu thêm Snack và Định lượng)
    return `
    Act as a professional Vietnamese Nutritionist and Chef.
    Create a detailed 1-day meal plan (Vietnamese cuisine) based on the following profile:

    - Gender: ${gender}
    - Age: ${age}
    - BMI: ${bmi} (${bmiStatus})
    - Goal: ${goal}
    - Target Calories: ${targetCalories} kcal
    - Health Conditions: ${healthStr}
    - Eating Habits: ${habitStr}
    - Diet Type: ${dietStr}
    - ⚠️ RESTRICTIONS/ALLERGIES (MUST AVOID): ${restrictionStr}

    IMPORTANT REQUIREMENTS:
    1. **Cuisine:** Must be Vietnamese dishes, easy to cook, ingredients available in Vietnam.
    2. **Safety First:** CHECK THE INGREDIENTS TWICE. Do NOT use any item listed in "RESTRICTIONS/ALLERGIES". 
       - If a traditional dish usually contains a restricted item, SUBSTITUTE it with a safe alternative.
    3. **Macros:** Calculate Protein, Carbs, Fat (in grams) ensuring they align with the User's Goal.
    4. **Quantities:** Ingredients MUST have estimated quantities (e.g., "100g Thịt bò", "1 quả trứng").
    5. **Data Format:** ALL NUMERIC VALUES MUST BE RAW NUMBERS (Integers or Floats). DO NOT ADD UNITS like 'g', 'kcal', 'mg'.
    6. **Language:** JSON Keys MUST be in English. Content values (Name, Description, Instructions) MUST be in Vietnamese.
    7. **Output Format:** Return ONLY raw JSON. No Markdown formatting (\`\`\`json). No introductory text.

    RESPONSE JSON STRUCTURE:
    {
        "nutritionTargets": { 
            "calories": ${targetCalories}, 
            "carbs": 150,  // Number only (grams)
            "protein": 100, // Number only (grams)
            "fat": 50,      // Number only (grams)
            "water": "2 - 6 lít" // String is ok here
        },
        "recommendations": ["Lời khuyên dinh dưỡng 1 ngắn gọn", "Lời khuyên 2"],
        "foodsToAvoid": ["Tên thực phẩm kỵ 1", "Tên thực phẩm kỵ 2"],
        "mealSuggestions": [
            {
                "session": "Bữa Sáng",
                "name": "Tên món ăn (Tiếng Việt)",
                "difficulty": "Dễ","Trung bình","Khó",
                "calories": 500, // Number only
                "time": "30 phút",
                "description": "Mô tả ngắn gọn hương vị",
                "ingredients": ["100g Phở tươi", "50g Thịt bò tái", "Hành tây, gừng nướng"],
                "instructions": ["Bước 1: Chần phở...", "Bước 2: Nấu nước dùng..."],
                "macros": { "carbs": 40, "fat": 10, "protein": 25 }
            },
            { 
                "session": "Bữa Trưa", 
                "name": "...", 
                "difficulty": "...",
                "calories": 700, 
                "time": "...", 
                "description": "...", 
                "ingredients": [], 
                "instructions": [], 
                "macros": { "carbs": 60, "fat": 20, "protein": 30 } 
            },
            { 
                "session": "Bữa Phụ (Chiều)", // Thêm bữa phụ để chia nhỏ calories
                "name": "...", 
                "difficulty": "...",
                "calories": 200, 
                "time": "5 phút", 
                "description": "...", 
                "ingredients": [], 
                "instructions": [], 
                "macros": { "carbs": 20, "fat": 5, "protein": 10 } 
            },
            { 
                "session": "Bữa Tối", 
                "name": "...", 
                "difficulty": "...",
                "calories": 400, 
                "time": "...", 
                "description": "...", 
                "ingredients": [], 
                "instructions": [], 
                "macros": { "carbs": 30, "fat": 10, "protein": 20 } 
            }
        ]
    }`;
};

module.exports = {
    generateMealPlanPrompt
};