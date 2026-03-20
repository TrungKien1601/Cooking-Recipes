const RecipeService = require('../../services/admin/recipe.service');
const ActivityLogService = require('../../services/admin/actlog.service');
const AdminService = require('../../services/admin/admin.service');
const NotificationService = require('../../services/admin/notification.service');

// Helper: Parse chuỗi JSON thành Object/Array (vì FormData gửi dữ liệu phức tạp dạng string)
const parseJSON = (data) => {
    try {
        if (!data) return undefined;
        return typeof data === 'string' ? JSON.parse(data) : data;
    } catch (e) {
        console.error("Lỗi parse JSON:", e.message);
        return []; // Trả về mảng rỗng hoặc giữ nguyên data tuỳ logic
    }
};

const getRecipes = async (req, res) => {
    try {
        // (Tuỳ chọn) Check quyền xem
        // const user = await AdminService.selectById(req.decoded._id);
        // if (user.role.roleName === 'User') return res.status(403)...

        const result = await RecipeService.selectAll();
        if (!result || result.length === 0) {
            return res.status(200).json({success: false, message: "Không có dữ liệu"});
        }
        return res.status(200).json({success: true, message: "Lấy thành công", recipes: result});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liệu", err)
        return res.status(500).json({success: false, message: "Lỗi server", error: err.message});
    }
};

const addNewRecipe = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const body = req.body;

        // Validate cơ bản
        if (!body.name) {
            return res.status(400).json({success: false, message: "Tên món ăn là bắt buộc"});
        }

        // 1. Xử lý file (Image & Video)
        let imagePath = '';
        let videoPath = '';

        // req.files['tên_field'] trả về mảng các file
        if (req.files && req.files['image']) {
            imagePath = 'uploads/' + req.files['image'][0].filename; 
        } else {
            return res.status(400).json({success: false, message: "Vui lòng tải lên ảnh đại diện món ăn"});
        }

        if (req.files && req.files['video']) {
            videoPath = 'videos/' + req.files['video'][0].filename;
        }

        // 2. Chuẩn bị dữ liệu
        // Lưu ý: Dùng parseJSON cho các trường Array/Object
        const newRecipeData = {
            name: body.name,
            description: body.description,
            author: user._id,
            image: imagePath,
            video: videoPath,
            servings: body.servings,
            cookTimeMinutes: body.cookTimeMinutes,
            difficulty: body.difficulty || 'Trung bình',
            status: body.status || 'Đã duyệt',
            
            ingredients: parseJSON(body.ingredients),
            steps: parseJSON(body.steps),
            nutritionAnalysis: parseJSON(body.nutritionAnalysis),
            
            mealTimeTags: parseJSON(body.mealTimeTags),
            dietTags: parseJSON(body.dietTags),
            regionTags: parseJSON(body.regionTags),
            dishtypeTags: parseJSON(body.dishtypeTags)
        };

        const result = await RecipeService.createRecipe(newRecipeData);

        // 3. Ghi log
        ActivityLogService.createLog({
            adminId: user._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "CREATE",
            targetCollection: 'Recipe',
            targetId: result._id,
            targetName: result.name,
            description: `${user.role.roleName} ${user.username} đã tạo món ăn: ${result.name}`,
            req: req
        });

        // Tạo thông báo cho Admin
        await NotificationService.createNotification({
            type: 'RECIPE_NEW',
            message: `Thành viên ${user.username} vừa gửi bài "${result.name}" chờ duyệt.`,
            referenceId: result._id,
            referenceModel: 'Recipe' // Khớp với tên model trong Recipe.js
        });

        return res.status(201).json({ success: true, message: "Thêm món ăn thành công", recipe: result});

    } catch (err) {
        console.error("Lỗi khi thêm món ăn", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra", error: err.message});
    }
};

const updateRecipe = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({ success: false, message: "Bạn không có quyền." });
        }

        const recipeId = req.params.id;
        const body = req.body;

        const updateData = { ...body }; // Copy dữ liệu text cơ bản

        // Xử lý JSON string nếu có gửi lên
        if (body.ingredients) updateData.ingredients = parseJSON(body.ingredients);
        if (body.steps) updateData.steps = parseJSON(body.steps);
        if (body.nutritionAnalysis) updateData.nutritionAnalysis = parseJSON(body.nutritionAnalysis);
        
        if (body.mealTimeTags) updateData.mealTimeTags = parseJSON(body.mealTimeTags);
        if (body.dietTags) updateData.dietTags = parseJSON(body.dietTags);
        if (body.regionTags) updateData.regionTags = parseJSON(body.regionTags);
        if (body.dishtypeTags) updateData.dishtypeTags = parseJSON(body.dishtypeTags);

        // Xử lý file (Chỉ update nếu có file mới)
        if (req.files) {
            if (req.files['image']) {
                updateData.image = 'uploads/' + req.files['image'][0].filename;
            }
            if (req.files['video']) {
                updateData.video = 'videos/' + req.files['video'][0].filename;
            }
        }

        const updatedRecipe = await RecipeService.updateRecipeById(recipeId, updateData);

        if (!updatedRecipe) {
            return res.status(404).json({success: false, message: "Món ăn không tồn tại"});
        }

        ActivityLogService.createLog({
            adminId: user._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "UPDATE",
            targetCollection: 'Recipe',
            targetId: updatedRecipe._id,
            targetName: updatedRecipe.name,
            description: `${user.role.roleName} ${user.username} đã cập nhật món ăn: ${updatedRecipe.name}`,
            req: req
        });

        return res.status(200).json({success: true, message: "Cập nhật thành công", recipe: updatedRecipe});

    } catch (err) {
        console.error("Lỗi khi cập nhật", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra", error: err.message});
    }
};

const deleteRecipe = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({ success: false, message: "Bạn không có quyền." });
        }

        const recipeId = req.params.id;
        const deletedRecipe = await RecipeService.deleteRecipeById(recipeId);

        if (!deletedRecipe) {
            return res.status(404).json({success: false, message: "Món ăn không tồn tại"});
        }

        ActivityLogService.createLog({
            adminId: user._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "DELETE",
            targetCollection: 'Recipe',
            targetId: deletedRecipe._id,
            targetName: deletedRecipe.name,
            description: `${user.role.roleName} ${user.username} đã xoá món ăn: ${deletedRecipe.name}`,
            req: req
        });

        return res.status(200).json({success: true, message: "Xoá thành công", recipe: deletedRecipe});

    } catch (err) {
        console.error("Lỗi khi xoá", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra", error: err.message});
    }
};

module.exports = { getRecipes, addNewRecipe, updateRecipe, deleteRecipe };