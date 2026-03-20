const { GoogleGenerativeAI } = require("@google/generative-ai");
const Recipe = require('../../models/Recipe');
const Notification = require('../../models/Notification');
const MasterIngredient = require('../../models/MasterIngredients');
const Tag = require('../../models/Tag');
const Collection = require('../../models/Collection');
const { getNutritionAnalysisPrompt } = require("../../utils/RecipePrompt");

const DIFFICULTY_ENUM = {
    EASY: 'Dễ',
    MEDIUM: 'Trung bình',
    HARD: 'Khó'
};

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash", 
    generationConfig: { responseMimeType: "application/json" }
});

// --- Helper Functions ---
function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const convertToGrams = (quantity, unit) => {
    if (!unit || !quantity) return 0;
    const u = unit.toLowerCase().trim();
    const q = parseFloat(quantity);

    // 1. Nhóm chuẩn
    if (['g', 'gram', 'gr', 'ml', 'gam'].includes(u)) return q;
    if (['kg', 'kilogram', 'kí', 'l', 'lít', 'liter'].includes(u)) return q * 1000;
    
    // 2. Nhóm ước lượng
    if (['tbsp', 'thìa canh', 'muỗng canh'].includes(u)) return q * 15;
    if (['tsp', 'thìa cà phê', 'muỗng cà phê'].includes(u)) return q * 5;
    if (['cup', 'chén', 'bát'].includes(u)) return q * 240;
    if (['củ', 'quả', 'trái'].includes(u)) return q * 100; // Ước lượng trung bình

    return 0;
};

const recipeService = {
    getDifficultyEnum() {
        return Object.values(DIFFICULTY_ENUM);
    },

    async getTagsForCreateRecipe() {
        const tags = await Tag.find({
            type: { $in: ['Độ khó', 'Giờ ăn', 'Chế độ ăn kiêng', 'Vùng miền', 'Cách chế biến'] }
        }).lean();

        return {
            difficultyTags: tags.filter(tag => tag.type === 'Độ khó'),
            mealTimeTags: tags.filter(tag => tag.type === 'Giờ ăn'),
            dietTags: tags.filter(tag => tag.type === 'Chế độ ăn kiêng'),
            regionTags: tags.filter(tag => tag.type === 'Vùng miền'),
            dishtypeTags: tags.filter(tag => tag.type === 'Cách chế biến')
        };
    },

    // --- 1. Process Ingredients (Core Logic) ---
    async processRecipeIngredients(ingredients) {
        if (!ingredients || ingredients.length === 0) {
            return {
                processedIngredients: [],
                totalNutrition: { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 }
            };
        }
        const queryConditions = ingredients.map(item => {
            const regex = new RegExp(`^${escapeRegExp(item.name.trim())}$`, 'i');
            return { $or: [{ name: regex }, { synonyms: regex }] };
        });

        const foundMasters = await MasterIngredient.find({ $or: queryConditions }).lean();

        let processedIngredients = [];
        let totalNutrition = { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 };

        for (let item of ingredients) {
            const itemNameClean = item.name.trim().toLowerCase();
            const master = foundMasters.find(m => 
                m.name.toLowerCase() === itemNameClean || 
                (m.synonyms && m.synonyms.some(s => s.toLowerCase() === itemNameClean))
            );

            let newItem = {
                name: item.name,
                quantity: parseFloat(item.quantity) || 0,
                unit: item.unit,
                masterIngredient: master ? master._id : null
            };
            if (master && master.nutritionPer100g) {
                const quantityInGrams = convertToGrams(newItem.quantity, newItem.unit);
                if (quantityInGrams > 0) {
                    const ratio = quantityInGrams / 100;
                    totalNutrition.calories += (master.nutritionPer100g.calories || 0) * ratio;
                    totalNutrition.protein += (master.nutritionPer100g.protein || 0) * ratio;
                    totalNutrition.carbs += (master.nutritionPer100g.carbs || 0) * ratio;
                    totalNutrition.fat += (master.nutritionPer100g.fat || 0) * ratio;
                    totalNutrition.sodium += (master.nutritionPer100g.sodium || 0) * ratio;
                    totalNutrition.sugars += (master.nutritionPer100g.sugars || 0) * ratio;
                }
            }
            processedIngredients.push(newItem);
        }

        return {
            processedIngredients,
            totalNutrition: {
                calories: Math.round(totalNutrition.calories),
                protein: Number(totalNutrition.protein.toFixed(1)),
                carbs: Number(totalNutrition.carbs.toFixed(1)),
                fat: Number(totalNutrition.fat.toFixed(1)),
                sodium: Math.round(totalNutrition.sodium),
                sugars: Number(totalNutrition.sugars.toFixed(1))
            }
        };
    },

    async createRecipe(userId, recipeData) {
        const { processedIngredients, totalNutrition } = await this.processRecipeIngredients(recipeData.ingredients);
            
        const finalNutrition = (recipeData.nutritionAnalysis && recipeData.nutritionAnalysis.calories > 0)
            ? recipeData.nutritionAnalysis
            : totalNutrition;

        let safeDifficulty = recipeData.difficulty;
        if (!Object.values(DIFFICULTY_ENUM).includes(safeDifficulty)) {
            safeDifficulty = DIFFICULTY_ENUM.MEDIUM;
        }

        const newRecipe = new Recipe({
            ...recipeData,
            author: userId,
            difficulty: safeDifficulty,
            ingredients: processedIngredients,
            nutritionAnalysis: finalNutrition,
            status: 'Chờ duyệt',
            createdAt: new Date()
        });

        const savedRecipe = await newRecipe.save();

        // Cập nhật Collection User
        // await Collection.findOneAndUpdate(
        //     { owner: userId },
        //     { $addToSet: { recipes: savedRecipe._id } },
        //     { upsert: true }
        // );

        await Notification.create({
            recipient: userId,
            title: "Đăng bài thành công 🎉",
            message: `Chúc mừng! Món "${savedRecipe.name}" của bạn đã được gửi xét duyệt.`,
            type: 'Đã duyệt', 
            targetId: savedRecipe._id,
            createdAt: new Date()
        });
        return savedRecipe;
    },

    async updateRecipe(id, userId, updateData) {
        const recipe = await Recipe.findOne({ _id: id, author: userId });
        if (!recipe) throw new Error("Không có quyền sửa hoặc bài viết không tồn tại");

        delete updateData.author;
        delete updateData._id;
        delete updateData.createdAt;

        if (updateData.difficulty && !Object.values(DIFFICULTY_ENUM).includes(updateData.difficulty)) {
            delete updateData.difficulty;
        }

        if (updateData.ingredients) {
            const { processedIngredients, totalNutrition } = await this.processRecipeIngredients(updateData.ingredients);
            updateData.ingredients = processedIngredients;
            if (!updateData.nutritionAnalysis || updateData.nutritionAnalysis.calories === 0) {
                 updateData.nutritionAnalysis = totalNutrition;
            }
        }
        
        Object.assign(recipe, updateData);
        return await recipe.save();
    },

    async deleteRecipe(id, userId, userRole = 'user') {
        const recipe = await Recipe.findById(id);
        if (!recipe) return null;

        if (recipe.author.toString() !== userId.toString() && userRole !== 'admin') {
            throw new Error("Không có quyền xóa");
        }
        await Recipe.findByIdAndDelete(id);
        await Collection.updateMany(
            { recipes: id },
            { $pull: { recipes: id } }
        );
        await Notification.deleteMany({ targetId: id });
        return true;
    },
    async analyzeNutrition(ingredients, servings) {
        const emptyData = { calories: 0, protein: 0, carbs: 0, fat: 0, sugars: 0, sodium: 0 };
        try {
            if (!ingredients || ingredients.length === 0) return emptyData;

            const numServings = servings && servings > 0 ? servings : 1;
            const prompt = getNutritionAnalysisPrompt(ingredients, numServings);
            // 2. Gọi Gemini
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            
            console.log("🤖 AI Response:", text); // Debug xem AI trả gì

            // 3. Clean JSON bằng Regex (Chống lỗi nếu AI trả về Markdown ```json ... ```)
            const jsonMatch = text.match(/\{[\s\S]*\}/);
            
            if (!jsonMatch) {
                console.error("❌ AI Output Invalid (No JSON found):", text);
                return emptyData;
            }

            try {
                return JSON.parse(jsonMatch[0]);
            } catch (e) {
                console.error("❌ JSON Parse Error:", e.message);
                return emptyData;
            }

        } catch (error) {
            console.error("🔥 Gemini AI Error:", error);
            return emptyData;
        }
    },

    async searchIngredients(query) {
        if (!query) return [];
        return await MasterIngredient.find({
            $or: [
                { name: { $regex: query, $options: 'i' } },
                { synonyms: { $regex: query, $options: 'i' } }
            ]
        }).select('name unit category image nutritionPer100g').limit(10);
    },

    async updateRecipeStatus(recipeId, newStatus) {
        const currentRecipe = await Recipe.findById(recipeId);
        if (!currentRecipe) throw new Error("Không tìm thấy công thức");
        if (currentRecipe.status === newStatus) return currentRecipe;

        const updatedRecipe = await Recipe.findByIdAndUpdate(
            recipeId,
            { status: newStatus },
            { new: true }
        );
        return updatedRecipe;
    },

    async getUserNotifications(userId) {
        return await Notification.find({ recipient: userId }).sort({ createdAt: -1 }).limit(50);
    },

    async markNotificationRead(notificationId, userId) {
        return await Notification.findOneAndUpdate(
            { _id: notificationId, recipient: userId },
            { isRead: true },
            { new: true }
        );
    },

    async deleteNotification(notificationId, userId) {
        return await Notification.findOneAndDelete({ _id: notificationId, recipient: userId });
    },

    async toggleSaveRecipe(userId, recipeId) {
        let collection = await Collection.findOne({ owner: userId });
        if (!collection) {
            collection = await Collection.create({
                owner: userId,
                recipes: [recipeId]
            });
            return { message: 'Đã lưu bài viết', isSaved: true };
        }
        
        const isExist = collection.recipes.some(r => r.toString() === recipeId.toString());
        
        if (isExist) {
            await Collection.findByIdAndUpdate(collection._id, { $pull: { recipes: recipeId } });
            return { message: 'Đã bỏ lưu', isSaved: false };
        } else {
            await Collection.findByIdAndUpdate(collection._id, { $addToSet: { recipes: recipeId } });
            return { message: 'Đã lưu bài viết', isSaved: true };
        }
    },

    async getSavedRecipes(userId, page = 1, limit = 10) {
        const skip = (page - 1) * limit;
        const collection = await Collection.findOne({ owner: userId });
        
        if (!collection || !collection.recipes.length) {
            return { recipes: [], total: 0, totalPages: 0, currentPage: page };
        }

        const allRecipeIds = collection.recipes.reverse(); 
        const total = allRecipeIds.length;
        const pagedIds = allRecipeIds.slice(skip, skip + limit);

        const recipes = await Recipe.find({ _id: { $in: pagedIds } })
            .select('name image cookTime difficulty author nutritionAnalysis')
            .populate('author', 'name avatar')
            .lean();
            
        const orderedRecipes = pagedIds
            .map(id => recipes.find(r => r._id.toString() === id.toString()))
            .filter(r => r != null); 

        return { recipes: orderedRecipes, total, totalPages: Math.ceil(total / limit), currentPage: page };
    },

    async checkIsSaved(userId, recipeId) {
        const collection = await Collection.findOne({ owner: userId });
        if (!collection) return false;
        return collection.recipes.some(r => r.toString() === recipeId.toString());
    },

    async getAllRecipes(filters, page = 1, limit = 10, userId = null) {
        const skip = (page - 1) * limit;
        const query = { status: 'Đã duyệt' };

        if (filters.authorId) {
            query.author = filters.authorId;
            if (filters.status) query.status = filters.status;
        }

        if (filters.search) {
            query.$text = { $search: filters.search }; 
        }

        if (filters.excludeAi === 'true') {
            query.isAiGenerated = { $ne: true };
        }

        if (filters.dietTags && filters.dietTags.length > 0) query.dietTags = { $in: filters.dietTags };
        if (filters.mealTimeTags && filters.mealTimeTags.length > 0) query.mealTimeTags = { $in: filters.mealTimeTags };
        if (filters.regionTags && filters.regionTags.length > 0) query.regionTags = { $in: filters.regionTags };
        if (filters.dishtypeTags && filters.dishtypeTags.length > 0) query.dishtypeTags = { $in: filters.dishtypeTags };
        
        if (filters.difficulty) query.difficulty = filters.difficulty;

        const [recipes, total] = await Promise.all([
            Recipe.find(query)
                .populate('author', 'name avatar')
                .populate('mealTimeTags dietTags regionTags dishtypeTags')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Recipe.countDocuments(query)
        ]);

        let savedRecipeIds = new Set();
        if (userId) {
            const collection = await Collection.findOne({ owner: userId }).lean();
            if (collection && collection.recipes) {
                savedRecipeIds = new Set(collection.recipes.map(id => id.toString()));
            }
        }

        const recipesWithStatus = recipes.map(recipe => ({
            ...recipe,
            isSaved: savedRecipeIds.has(recipe._id.toString())
        }));

        return {
            recipes: recipesWithStatus,
            total,
            totalPages: Math.ceil(total / limit),
            currentPage: page
        };
    },

    async getRecipeById(id) {
        return await Recipe.findById(id)
            .populate('author', 'name avatar email')
            .populate('ingredients.masterIngredient', 'name image category nutritionPer100g')
            .populate('mealTimeTags dietTags regionTags dishtypeTags');
    },
};

module.exports = recipeService;