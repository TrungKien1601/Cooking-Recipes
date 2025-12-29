const { GoogleGenerativeAI } = require("@google/generative-ai");
const Recipe = require('../../models/Recipe');
const Notification = require('../../models/Notification');
const MasterIngredient = require('../../models/MasterIngredients');
const Tag = require('../../models/Tag');
const { getNutritionAnalysisPrompt } = require("../../utils/RecipePrompt");

// --- Helper: Escape Regex ---
function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); 
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash",
    generationConfig: { responseMimeType: "application/json" }
});

const recipeService = {

    // --- 0. Lấy tags ---
    async getTagsForCreateRecipe() {
        try {
            const tags = await Tag.find({
                type: { $in: ['Giờ ăn', 'Chế độ ăn kiêng','Vùng miền','Cách chế biến'] }
            }).lean();

            return {
                mealTimeTags: tags.filter(tag => tag.type === 'Giờ ăn'),
                dietTags: tags.filter(tag => tag.type === 'Chế độ ăn kiêng'),
                regionTags: tags.filter(tag => tag.type === 'Vùng miền'),
                dishtypeTags: tags.filter(tag => tag.type === 'Cách chế biến')
            };
        } catch (error) {
            throw error;
        }
    },

    // --- 1. Xử lý nguyên liệu & Dinh dưỡng ---
    async processRecipeIngredients(ingredients) {
        if (!ingredients || ingredients.length === 0) {
            return {
                processedIngredients: [],
                totalNutrition: { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 }
            };
        }

        const searchPatterns = ingredients.map(item => new RegExp(`^${escapeRegExp(item.name.trim())}$`, 'i'));

        const foundMasters = await MasterIngredient.find({
            $or: [
                { name: { $in: searchPatterns } },
                { synonyms: { $in: searchPatterns } }
            ]
        });

        let processedIngredients = [];
        let totalNutrition = { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 };

        for (let item of ingredients) {
            const itemNameClean = item.name.trim();

            const master = foundMasters.find(m => {
                const isNameMatch = new RegExp(`^${m.name}$`, 'i').test(itemNameClean);
                const isSynonymMatch = m.synonyms 
                    ? m.synonyms.some(syn => new RegExp(`^${syn}$`, 'i').test(itemNameClean))
                    : false;
                return isNameMatch || isSynonymMatch;
            });

            let newItem = {
                name: item.name,
                quantity: parseFloat(item.quantity) || 0,
                unit: item.unit,
                masterIngredient: master ? master._id : null
            };

            if (master && master.nutritionPer100g) {
                let quantityInGrams = 0;
                const u = item.unit ? item.unit.toLowerCase().trim() : '';
                if (['kg', 'kilogram', 'kí'].includes(u)) quantityInGrams = newItem.quantity * 1000;
                else if (['g', 'gram', 'gr', 'ml', 'gam'].includes(u)) quantityInGrams = newItem.quantity;
                else if (['l', 'lít', 'liter'].includes(u)) quantityInGrams = newItem.quantity * 1000;

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
                protein: parseFloat(totalNutrition.protein.toFixed(1)),
                carbs: parseFloat(totalNutrition.carbs.toFixed(1)),
                fat: parseFloat(totalNutrition.fat.toFixed(1)),
                sodium: Math.round(totalNutrition.sodium),
                sugars: parseFloat(totalNutrition.sugars.toFixed(1))
            }
        };
    },

    // --- 2. Create Recipe ---
    async createRecipe(userId, recipeData) {
        const { processedIngredients, totalNutrition } = await this.processRecipeIngredients(recipeData.ingredients);

        const finalNutrition = (recipeData.nutritionAnalysis && recipeData.nutritionAnalysis.calories > 0)
            ? recipeData.nutritionAnalysis
            : totalNutrition;

        const newRecipe = new Recipe({
            ...recipeData,
            author: userId,
            ingredients: processedIngredients,
            nutritionAnalysis: finalNutrition,
            status: 'Đã duyệt'
        });

        const savedRecipe = await newRecipe.save();

        // Gửi thông báo kèm targetId
        await Notification.create({
            recipient: userId,
            title: "Đăng bài thành công 🎉",
            message: `Chúc mừng! Món "${savedRecipe.name}" của bạn đã được đăng.`,
            type: 'Đã duyệt',
            targetId: savedRecipe._id, 
            createdAt: new Date()
        });

        return savedRecipe;
    },

    // --- 3. Get Recipes ---
    // Update: Chỉnh sửa getAllRecipes để hỗ trợ lấy danh sách yêu thích
    async getAllRecipes(filters, page = 1, limit = 10, userId = null) { // Thêm userId
        const skip = (page - 1) * limit;
        const query = { status: 'Đã duyệt' };

        if (filters.status) query.status = filters.status;
        if (filters.search) query.$text = { $search: filters.search };
        if (filters.authorId) {
            query.author = filters.authorId;
            delete query.status; 
        }

        if (filters.dietTags) query.dietTags = { $in: filters.dietTags };
        if (filters.mealTimeTags) query.mealTimeTags = { $in: filters.mealTimeTags };
        if (filters.regionTags) query.regionTags = { $in: filters.regionTags };
        if (filters.dishtypeTags) query.dishtypeTags = { $in: filters.dishtypeTags };
        if (filters.difficulty) query.difficulty = filters.difficulty;

        const recipes = await Recipe.find(query)
            .populate('author', 'name avatar')
            .populate('mealTimeTags dietTags regionTags dishtypeTags')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean(); // Dùng lean() để trả về object thuần

        const total = await Recipe.countDocuments(query);

        // Map isFavorite
        const recipesWithFavorite = recipes.map(recipe => {
             return {
                 ...recipe,
                 isFavorite: recipe.likes ? recipe.likes.some(id => id.toString() === (userId ? userId.toString() : '')) : false,
                 likeCount: recipe.likes ? recipe.likes.length : 0
             };
        });

        return {
            recipes: recipesWithFavorite,
            total,
            totalPages: Math.ceil(total / limit),
            currentPage: page
        };
    },

    // --- 3.5. Get Favorite Recipes (MỚI THÊM) ---
    async getMyFavoriteRecipes(userId) {
        // Chỉ tìm những Recipe mà mảng 'likes' có chứa userId này
        const recipes = await Recipe.find({ likes: userId })
            .populate('author', 'name avatar') // Sửa thành author cho khớp model
            .populate('mealTimeTags dietTags regionTags dishtypeTags')
            .sort({ createdAt: -1 })
            .lean();

        // Vì đây là danh sách yêu thích, mặc định isFavorite = true
        return recipes.map(recipe => ({
            ...recipe,
            isFavorite: true,
            likeCount: recipe.likes ? recipe.likes.length : 0
        }));
    },

    // --- 3.6 Toggle Like (MỚI THÊM) ---
    async toggleLike(userId, recipeId) {
        const recipe = await Recipe.findById(recipeId);
        if (!recipe) throw new Error("Công thức không tồn tại");

        // Đảm bảo likes là mảng
        if (!recipe.likes) recipe.likes = [];

        // Kiểm tra xem user đã like chưa
        const index = recipe.likes.indexOf(userId);

        let status = false; // false = bỏ like, true = đã like

        if (index === -1) {
            // Chưa like -> Thêm vào (Like)
            recipe.likes.push(userId);
            status = true;
        } else {
            // Đã like -> Xóa đi (Unlike)
            recipe.likes.splice(index, 1);
            status = false;
        }

        await recipe.save();
        return status; // Trả về true/false để Frontend đổi màu tim
    },


    // --- 4. CRUD & AI ---
    async getRecipeById(id) {
        return await Recipe.findById(id)
            .populate('author', 'name avatar email')
            .populate('ingredients.masterIngredient', 'name image category')
            .populate('mealTimeTags dietTags regionTags dishtypeTags');
    },

    async updateRecipe(id, userId, updateData) {
        const recipe = await Recipe.findOne({ _id: id, author: userId });
        if (!recipe) throw new Error("Không có quyền sửa bài này");

        delete updateData.author;
        delete updateData._id;
        delete updateData.createdAt;

        if (updateData.ingredients) {
            const { processedIngredients, totalNutrition } = await this.processRecipeIngredients(updateData.ingredients);
            updateData.ingredients = processedIngredients;
            if (!updateData.nutritionAnalysis) updateData.nutritionAnalysis = totalNutrition;
        }
        updateData.status = 'Đã duyệt'; 
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

        if (userRole === 'admin') {
            await Notification.create({
                recipient: recipe.author,
                title: "Bài viết đã bị xóa ⚠️",
                message: `Bài viết "${recipe.name}" vi phạm quy định nên đã bị xóa.`,
                type: 'Đã xóa', 
                targetId: null,
                isRead: false
            });
        }
        await Notification.deleteMany({ targetId: id });
        return true;
    },

    async analyzeNutrition(ingredients, servings) { // <--- Thêm tham số servings vào đây
        try {
            if (!ingredients || ingredients.length === 0) return null;
            
            // Mặc định là 1 nếu client không gửi lên
            const numServings = servings && servings > 0 ? servings : 1; 
            // Truyền servings vào Prompt
            const prompt = getNutritionAnalysisPrompt(ingredients, numServings); 
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            return JSON.parse(text.replace(/```json|```/g, '').trim());
        } catch (error) {
            console.log("AI Error:", error);
            return null;
        }
    },

    async searchIngredients(query) {
        if (!query) return [];
        return await MasterIngredient.find({
            $or: [
                { name: { $regex: query, $options: 'i' } },
                { synonyms: { $regex: query, $options: 'i' } }
            ]
        }).select('name unit category image').limit(10);
    },

    async updateRecipeStatus(recipeId, newStatus){
        try {
            const currentRecipe = await Recipe.findById(recipeId);
            if (!currentRecipe) throw new Error("Không tìm thấy công thức");
            if (currentRecipe.status === newStatus) return currentRecipe;

            const updatedRecipe = await Recipe.findByIdAndUpdate(
                recipeId,
                { status: newStatus },
                { new: true }
            );

            if (newStatus === 'Đã duyệt') {
                await Notification.create({
                    recipient: updatedRecipe.author,
                    title: "Bài viết được duyệt 🎉",
                    message: `Món "${updatedRecipe.name}" của bạn đã được duyệt.`,
                    type: 'Đã duyệt',
                    targetId: updatedRecipe._id,
                    createdAt: new Date()
                });
            } else if (newStatus === 'Từ chối') {
                await Notification.create({
                    recipient: updatedRecipe.author,
                    title: "Bài viết bị từ chối ⚠️",
                    message: `Món "${updatedRecipe.name}" chưa đạt tiêu chuẩn.`,
                    type: 'Từ chối',
                    targetId: updatedRecipe._id,
                    createdAt: new Date()
                });
            }
            return updatedRecipe;
        } catch (error) {
            throw new Error(`Lỗi cập nhật trạng thái: ${error.message}`);
        }
    },

    // --- 5. NOTIFICATION FEATURES (GỘP VÀO ĐÂY) ---
    
    // Lấy thông báo của user
    async getUserNotifications(userId) {
        return await Notification.find({ recipient: userId })
            .sort({ createdAt: -1 }) // Mới nhất lên đầu
            .limit(50); // Lấy 50 cái thôi cho nhẹ
    },

    // Đánh dấu đã đọc
    async markNotificationRead(notificationId, userId) {
        return await Notification.findOneAndUpdate(
            { _id: notificationId, recipient: userId },
            { isRead: true },
            { new: true }
        );
    },

    // Xóa thông báo (cho nút Delete bên Flutter)
    async deleteNotification(notificationId, userId) {
        return await Notification.findOneAndDelete({ 
            _id: notificationId, 
            recipient: userId 
        });
    }
};

module.exports = recipeService;