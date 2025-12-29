const Recipe = require('../../models/Recipe');

const RecipeService = {
    //Lấy dữ liệu
    async selectAll() {
        const query = [];
        const result = await Recipe.find(query).populate('author').exec();
        return result;
    },

    //Tạo mới
    async createRecipe(recipe) {
        const result = (await Recipe.create(recipe)).populate('author');
        return result;
    },

    //Cập nhật
    async updateRecipeById(_id, recipe) {
        const config = { new: true, runValidators: true };
        const result = await Recipe.findByIdAndUpdate(_id, recipe, config).populate('author').exec();
        return result;
    },
    

    //Xoá
    async deleteRecipeById(_id) {
        const result = await Recipe.findByIdAndDelete(_id).populate('author').exec();
        return result;
    }
}

module.exports = RecipeService;