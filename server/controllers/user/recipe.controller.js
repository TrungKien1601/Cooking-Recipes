const recipeService = require('../../services/user/recipe.service');
const NotificationService = require('../../services/admin/notification.service');
const AdminService = require('../../services/admin/admin.service');

// --- Helpers Utilities ---
const getUserId = (req) => req.decoded?._id || req.user?._id;

const normalizeFilePath = (file) => {
    if (!file) return undefined;
    let path = file.path.replace(/\\/g, "/");
    return path.startsWith('public/') ? path.replace('public/', '') : path;
};

// Hàm parse JSON an toàn tuyệt đối
const parseSafeJSON = (dataStr, fallback = undefined) => {
    if (typeof dataStr !== 'string') return dataStr; 
    if (!dataStr || dataStr === 'null' || dataStr === 'undefined') return fallback;
    try {
        return JSON.parse(dataStr);
    } catch (e) {
        console.warn(`JSON Parse Error for value: ${dataStr}`, e);
        return fallback; 
    }
};

const recipeController = {

    // 1. UPLOAD VIDEO
    uploadVideo: async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).json({ 
                    success: false, 
                    message: "Vui lòng chọn video hợp lệ (MP4, MOV...)" 
                });
            }
            const clientPath = normalizeFilePath(req.file);
            return res.status(200).json({ success: true, data: clientPath });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 2. CREATE RECIPE
    createRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            const user = await AdminService.selectById(userId);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });

            // Copy object để tránh thay đổi trực tiếp req.body
            const recipeData = { ...req.body };

            // Xử lý ảnh
            if (req.file) {
                recipeData.image = normalizeFilePath(req.file);
            }

            // Parse JSON fields với fallback an toàn
            const fieldsToParse = ['ingredients', 'steps', 'mealTimeTags', 'dietTags', 'regionTags', 'dishtypeTags'];
            fieldsToParse.forEach(field => {
                recipeData[field] = parseSafeJSON(recipeData[field], []); // Fallback là [] để loop không lỗi
            });

            // Parse Nutrition (Fallback là object rỗng)
            recipeData.nutritionAnalysis = parseSafeJSON(recipeData.nutritionAnalysis, {});

            if (!recipeData.difficulty || recipeData.difficulty === 'null') {
                recipeData.difficulty = 'Trung bình';
            }

            const newRecipe = await recipeService.createRecipe(userId, recipeData);
            await NotificationService.createNotification({
                type: 'RECIPE_NEW',
                message: `Thành viên ${user.username} vừa gửi bài "${newRecipe.name}" chờ duyệt.`,
                referenceId: newRecipe._id,
                referenceModel: 'Recipe' // Khớp với tên model trong Recipe.js
            });
            return res.status(201).json({ success: true, data: newRecipe });

        } catch (error) {
            console.error("Create Recipe Error:", error);
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 3. READ & GET
    getRecipeTags: async (req, res) => {
        try {
            const tags = await recipeService.getTagsForCreateRecipe();
            return res.status(200).json({ success: true, data: tags });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    getAllRecipes: async (req, res) => {
        try {
            const { 
                page, limit, search, 
                dietTags, mealTimeTags, regionTags, dishtypeTags, 
                difficulty, authorId, status, excludeAi 
            } = req.query;
            
            const userId = getUserId(req);

            const filters = {
                search, 
                status, 
                authorId, 
                excludeAi,
                dietTags: dietTags ? dietTags.split(',') : undefined,
                mealTimeTags: mealTimeTags ? mealTimeTags.split(',') : undefined,
                regionTags: regionTags ? regionTags.split(',') : undefined,
                dishtypeTags: dishtypeTags ? dishtypeTags.split(',') : undefined,
                difficulty 
            };

            const result = await recipeService.getAllRecipes(filters, parseInt(page) || 1, parseInt(limit) || 10, userId);
            
            return res.status(200).json({ 
                success: true, 
                data: result.recipes, 
                meta: { total: result.total, pages: result.totalPages } 
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    getRecipeById: async (req, res) => {
        try {
            const recipe = await recipeService.getRecipeById(req.params.id);
            if (!recipe) return res.status(404).json({ success: false, message: "Không tìm thấy công thức" });
            
            const userId = getUserId(req);
            let isSaved = false;
            let isFavorite = false;

            if (userId) {
                // Check isSaved và isFavorite
                const savedStatus = await recipeService.checkIsSaved(userId, req.params.id);
                isSaved = savedStatus;
                
                // Kiểm tra mảng likes an toàn (optional chaining)
                if (recipe.likes?.some(id => id.toString() === userId.toString())) {
                    isFavorite = true;
                }
            }

            return res.status(200).json({ 
                success: true, 
                data: { 
                    ...recipe.toObject(), 
                    isSaved,
                    isFavorite
                } 
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 4. UPDATE
    updateRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            const updateData = { ...req.body };
            
            if (req.file) {
                updateData.image = normalizeFilePath(req.file);
            }

            const fieldsToParse = ['ingredients', 'steps', 'mealTimeTags', 'dietTags', 'regionTags', 'dishtypeTags'];
            fieldsToParse.forEach(field => {
                // Với update, fallback là undefined để không ghi đè dữ liệu cũ bằng mảng rỗng nếu user không gửi
                updateData[field] = parseSafeJSON(updateData[field], undefined);
            });
            updateData.nutritionAnalysis = parseSafeJSON(updateData.nutritionAnalysis, undefined);

            if (updateData.difficulty === 'null' || updateData.difficulty === 'undefined') {
                delete updateData.difficulty;
            }

            const updatedRecipe = await recipeService.updateRecipe(req.params.id, userId, updateData);
            return res.status(200).json({ success: true, data: updatedRecipe });
        } catch (error) {
            return res.status(400).json({ success: false, message: error.message });
        }
    },

    // 5. DELETE
    deleteRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            // Lấy role từ decoded token (Cần đảm bảo middleware auth đã gán decoded)
            const userRole = req.decoded?.role?.roleName || req.user?.role || 'user'; 
            
            const result = await recipeService.deleteRecipe(req.params.id, userId, userRole);
            if (!result) return res.status(404).json({ message: "Không tìm thấy bài viết hoặc không có quyền" });

            return res.status(200).json({ success: true, message: "Đã xóa bài viết thành công" });
        } catch (error) {
            return res.status(403).json({ success: false, message: error.message });
        }
    },

    // 6. FEATURES
    analyzeNutrition: async (req, res) => {
        try {
            const { ingredients, servings } = req.body;
            const analysis = await recipeService.analyzeNutrition(ingredients, servings);
            return res.status(200).json({ success: true, data: analysis });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    searchIngredients: async (req, res) => {
        try {
            const results = await recipeService.searchIngredients(req.query.q);
            return res.status(200).json({ success: true, data: results });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    updateStatus: async (req, res) => {
        try {
            // Frontend cần gửi body: { "status": "Đã duyệt" }
            const result = await recipeService.updateRecipeStatus(req.params.id, req.body.status);
            return res.status(200).json({ success: true, data: result });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 7. SAVED & NOTIFICATIONS
    getSavedRecipes: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });
            
            const { page, limit } = req.query;
            const result = await recipeService.getSavedRecipes(userId, parseInt(page) || 1, parseInt(limit) || 10);
            
            return res.status(200).json({ 
                success: true, 
                data: result.recipes,
                meta: {
                    total: result.total,
                    pages: result.totalPages,
                    currentPage: result.currentPage
                }
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    toggleSave: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });
            
            const { recipeId } = req.body;
            if (!recipeId) return res.status(400).json({ message: "Thiếu Recipe ID" });
            
            const result = await recipeService.toggleSaveRecipe(userId, recipeId);
            
            return res.status(200).json({ 
                success: true, 
                message: result.message, 
                isSaved: result.isSaved 
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    getMyNotifications: async (req, res) => {
        try {
            const userId = getUserId(req);
            const notifications = await recipeService.getUserNotifications(userId);
            return res.status(200).json({ success: true, data: notifications });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    markNotificationRead: async (req, res) => {
        try {
            const userId = getUserId(req);
            await recipeService.markNotificationRead(req.params.id, userId);
            return res.status(200).json({ success: true });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    deleteNotification: async (req, res) => {
        try {
            const userId = getUserId(req);
            const deleted = await recipeService.deleteNotification(req.params.id, userId);
            if (!deleted) return res.status(404).json({ success: false, message: "Không tìm thấy thông báo" });
            return res.status(200).json({ success: true, message: "Đã xóa thông báo" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }
};

module.exports = recipeController;