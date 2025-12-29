const IngredientService = require('../../services/admin/ingredient.service');
const AdminService = require('../../services/admin/admin.service');
const ActivityLogService = require('../../services/admin/actlog.service');

const getAndFilterIngredients = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const result = await IngredientService.selectAll();
        if (!result || result.length === 0) {
            return res.status(200).json({success: false, message: "Không có dữ liệu"})
        }
        return res.status(200).json({success: true, message: "Lấy dữ liệu thành công", ingredients: result});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liệu", err);
        return res.status(500).json({success: false, message: "Có lỗi ở server"});
    }
};

const createNewIngredient = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const name = req.body.name;
        const synonyms = req.body.synonyms;
        const nutritionPer100g = req.body.nutritionPer100g;
        const tag = req.body.tag;

        if (!name || !synonyms || !nutritionPer100g || !tag) return res.status(200).json({success: false, message: "Vui lòng không để trống"});

        const newIngre = { name: name, synonyms: synonyms, nutritionPer100g: nutritionPer100g, tag: tag };
        const result = await IngredientService.createIngredient(newIngre);

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "CREATE",
            targetCollection: 'MasterIngredient',
            targetId: result._id,
            targetName: result.name,
            description: `${user.role.roleName} ${user.username} đã tạo nguyên liệu mới ${result.name} có id là ${result._id}`,
            req: req
        });
        
        return res.status(200).json({success: true, message: "Tạo mới thành công"});
    } catch (err) {
        console.error("Lỗi khi lưu vào server", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình lưu", error: err.message});
    }
};

const updateIngredientById = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const id = req.params.id;
        const { name, synonyms, nutritionPer100g, tag } = req.body;

        if (!name || !synonyms || !nutritionPer100g || !tag) return res.status(400).json({success: false, message: "Vui lòng không để trống"});

        const ingre = { name: name, synonyms: synonyms, nutritionPer100g: nutritionPer100g, tag: tag };
        const result = await IngredientService.updateIngredientById(id, ingre);

        if(!result) return res.status(404).json({success: false, message: "Nguyên liệu không tồn tại"});

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "UPDATE",
            targetCollection: 'MasterIngredient',
            targetId: result._id,
            targetName: result.name,
            description: `${user.role.roleName} ${user.username} đã cập nhật nguyên liệu ${result.name} có id là ${result._id}`,
            req: req
        });

        return res.status(200).json({success: true, message: "Cập nhật thành công"});
    } catch (err) {
        console.error("Lỗi khi cập nhật vào server", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình cập nhật", error: err.message});
    }
};

const deleteIngredientById = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const id = req.params.id

        const result = await IngredientService.deleteIngredientById(id);
        if(!result) return res.status(404).json({success: false, message: "Nguyên liệu không tồn tại"});

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "DELETE",
            targetCollection: 'MasterIngredient',
            targetId: result._id,
            targetName: result.name,
            description: `${user.role.roleName} ${user.username} đã xoá nguyên liệu ${result.name} có id là ${result._id}`,
            req: req
        });

        return res.status(200).json({success: true, message: "Xoá thành công"});
    } catch (err) {
        console.error("Lỗi khi xoá dữ liệu", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình xoá", error: err.message});
    }
};

module.exports = { getAndFilterIngredients, createNewIngredient, updateIngredientById, deleteIngredientById };