const Recipe = require('../../models/Recipe');

const RecipeService = {
    // Lấy danh sách (Kèm thông tin chi tiết Tags và Author)
    async selectAll() {
        const query = {}; 
        
        const result = await Recipe.find(query)
            .populate('author', 'username email role') // Lấy thông tin người tạo (trừ pass)
            // Lấy chi tiết các thẻ (chỉ lấy tên và loại để response nhẹ hơn)
            .populate('mealTimeTags dietTags regionTags dishtypeTags', 'name type') 
            .sort({ updatedAt: -1 }) // Mới nhất lên đầu
            .exec();
            
        return result;
    },

    // Lấy chi tiết 1 món (Dùng cho trang Detail/Edit)
    async selectById(_id) {
        const result = await Recipe.findById(_id)
            .populate('author', 'username email')
            .populate('ingredients.masterIngredient', 'name') // Lấy tên nguyên liệu gốc
            .populate('mealTimeTags dietTags regionTags dishtypeTags')
            .exec();
        return result;
    },

    // Tạo mới
    async createRecipe(recipe) {
        const newRecipe = await Recipe.create(recipe);
        // Populate để trả về dữ liệu đầy đủ ngay sau khi tạo
        return await newRecipe.populate('author mealTimeTags dietTags regionTags dishtypeTags');
    },

    // Cập nhật
    async updateRecipeById(_id, recipe) {
        const config = { new: true, runValidators: true };
        const result = await Recipe.findByIdAndUpdate(_id, recipe, config)
            .populate('author mealTimeTags dietTags regionTags dishtypeTags')
            .exec();
        return result;
    },

    // Xoá
    async deleteRecipeById(_id) {
        const result = await Recipe.findByIdAndDelete(_id)
            .populate('author')
            .exec();
        return result;
    }
}

module.exports = RecipeService;