const recipeService = require('../../services/user/recipe.service');

// Helper lấy User ID (như cũ)
const getUserId = (req) => req.decoded?._id || req.user?._id;

const recipeController = {

    // ==========================================
    // 1. UPLOAD VIDEO (Xử lý tại chỗ, không cần gọi Service)
    // ==========================================
    uploadVideo: async (req, res) => {
        try {
            // Kiểm tra file từ Middleware (config/videos.js)
            if (!req.file) {
                return res.status(400).json({ 
                    success: false, 
                    message: "Vui lòng chọn video hợp lệ (MP4, MOV...)" 
                });
            }

            // Xử lý đường dẫn để trả về client
            // Đường dẫn gốc: public/videos/video_123.mp4
            // Đường dẫn trả về: videos/video_123.mp4 (để client ghép với domain)
            
            let clientPath = req.file.path.replace(/\\/g, "/"); // Fix lỗi dấu \ trên Windows
            
            if (clientPath.startsWith('public/')) {
                clientPath = clientPath.replace('public/', '');
            }

            return res.status(200).json({ 
                success: true, 
                data: clientPath 
            });

        } catch (error) {
            console.error("Lỗi upload video:", error);
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // ==========================================
    // 2. CREATE RECIPE (Có parse JSON để tránh lỗi CastError)
    // ==========================================
    createRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });

            const recipeData = req.body;
            
            // Xử lý ảnh (Thumbnail) nếu có upload kèm
            if (req.file) {
                let imagePath = req.file.path.replace(/\\/g, "/");
                if (imagePath.startsWith('public/')) {
                    imagePath = imagePath.replace('public/', '');
                }
                recipeData.image = imagePath;
            }

            // 👇 QUAN TRỌNG: Parse các trường JSON string từ Flutter gửi lên
            // Vì Flutter gửi MultipartRequest, mọi thứ đều là String
            const fieldsToParse = [
                'ingredients', 
                'nutritionAnalysis', 
                'steps', 
                'mealTimeTags', 
                'dietTags', 
                'regionTags', 
                'dishtypeTags'
            ];

            fieldsToParse.forEach(field => {
                if (typeof recipeData[field] === 'string') {
                    try {
                        // Nếu chuỗi rỗng hoặc "null", gán null hoặc mảng rỗng
                        if (recipeData[field] === 'null' || recipeData[field] === '') {
                             recipeData[field] = undefined;
                        } else {
                             recipeData[field] = JSON.parse(recipeData[field]);
                        }
                    } catch (e) {
                        console.error(`⚠️ Lỗi parse JSON trường ${field}:`, e.message);
                        // Không crash app, chỉ log lỗi
                    }
                }
            });

            // Gọi Service để lưu vào DB
            const newRecipe = await recipeService.createRecipe(userId, recipeData);
            return res.status(201).json({ success: true, data: newRecipe });

        } catch (error) {
            console.error("Create Recipe Error:", error);
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // ==========================================
    // 3. CÁC HÀM KHÁC (Giữ nguyên như cũ)
    // ==========================================
    
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
            const { page, limit, search, dietTags, mealTimeTags, regionTags, dishtypeTags, difficulty, authorId, status } = req.query;
            const userId = getUserId(req);

            const filters = {
                search, status, authorId,
                dietTags: dietTags ? dietTags.split(',') : undefined,
                mealTimeTags: mealTimeTags ? mealTimeTags.split(',') : undefined,
                regionTags: regionTags ? regionTags.split(',') : undefined,
                dishtypeTags: dishtypeTags ? dishtypeTags.split(',') : undefined,
                difficulty
            };
            const result = await recipeService.getAllRecipes(filters, parseInt(page), parseInt(limit), userId);
            return res.status(200).json({ success: true, data: result.recipes, meta: { total: result.total, pages: result.totalPages } });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    getRecipeById: async (req, res) => {
        try {
            const recipe = await recipeService.getRecipeById(req.params.id);
            if (!recipe) return res.status(404).json({ success: false, message: "Không tìm thấy công thức" });
            return res.status(200).json({ success: true, data: recipe });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    updateRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            const updateData = req.body;
            
            if (req.file) {
                let imagePath = req.file.path.replace(/\\/g, "/");
                if (imagePath.startsWith('public/')) imagePath = imagePath.replace('public/', '');
                updateData.image = imagePath;
            }

            // Parse JSON cho update
            const fieldsToParse = ['ingredients', 'nutritionAnalysis', 'steps', 'mealTimeTags', 'dietTags', 'regionTags', 'dishtypeTags'];
            fieldsToParse.forEach(field => {
                if (typeof updateData[field] === 'string') {
                    try { updateData[field] = JSON.parse(updateData[field]); } catch (e) {}
                }
            });

            const updatedRecipe = await recipeService.updateRecipe(req.params.id, userId, updateData);
            return res.status(200).json({ success: true, data: updatedRecipe });
        } catch (error) {
            return res.status(400).json({ success: false, message: error.message });
        }
    },

    deleteRecipe: async (req, res) => {
        try {
            const userId = getUserId(req);
            const userRole = req.decoded?.role?.roleName || 'user';
            await recipeService.deleteRecipe(req.params.id, userId, userRole);
            return res.status(200).json({ success: true, message: "Đã xóa bài viết thành công" });
        } catch (error) {
            return res.status(403).json({ success: false, message: error.message });
        }
    },

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
            const result = await recipeService.updateRecipeStatus(req.params.id, req.body.status);
            return res.status(200).json({ success: true, data: result });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // --- FAVORITES & LIKES ---
    getFavorites: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });
            const data = await recipeService.getMyFavoriteRecipes(userId);
            return res.status(200).json({ success: true, data: data });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    toggleLike: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ message: "Vui lòng đăng nhập" });
            const { recipeId } = req.body;
            if (!recipeId) return res.status(400).json({ message: "Thiếu Recipe ID" });
            const isLiked = await recipeService.toggleLike(userId, recipeId);
            return res.status(200).json({ success: true, message: isLiked ? "Đã thích" : "Đã bỏ thích", isFavorite: isLiked });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // --- NOTIFICATION ---
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
            if (!deleted) return res.status(404).json({ success: false, message: "Không tìm thấy hoặc không có quyền xóa" });
            return res.status(200).json({ success: true, message: "Đã xóa thông báo" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }
};

module.exports = recipeController;