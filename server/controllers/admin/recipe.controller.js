const RecipeService = require('../../services/admin/recipe.service');
const ActivityLogService = require('../../services/admin/actlog.service');
const AdminService = require('../../services/admin/admin.service');

const getRecipes = async (req, res) => {
    try {
        const result = await RecipeService.selectAll();
        if (!result || result.length === 0) {
            return res.status(200).json({success: false, message: "Không có dữ liệu"});
        }
        return res.status(200).json({success: true, message: "Lấy thành công", recipe: result});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liện", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình truy vấn dữ liệu", error: err.message});
    }
};

const addNewRecipe = async (req, res) => {
    try {
        
    } catch (err) {
        
    }
};

const updateRecipe = async (req, res) => {
    try {
        
    } catch (err) {
        
    }
};

const deleteRecipe = async (req, res) => {
    try {
        
    } catch (err) {
        
    }
};

module.exports = { getRecipes, addNewRecipe, updateRecipe, deleteRecipe };