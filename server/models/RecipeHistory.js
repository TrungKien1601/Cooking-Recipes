const mongoose = require('mongoose');

const RecipeHistorySchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  recipes: [
    {
      name: String,
      description: { type: String, default: "" }, 
      calories: Number,
      cooking_time: String,   
      ingredients_used: [String], 
      all_ingredients: [String],  
      instructions: [String],     
      steps: [String],            
      macros: {
        protein: { type: Number, default: 0 },
        carbs: { type: Number, default: 0 },
        fat: { type: Number, default: 0 }
      },
      image_url: String // Dự phòng nếu sau này muốn lưu ảnh
    }
  ]
}, { timestamps: true }); // Tự động tạo createdAt và updatedAt

module.exports = mongoose.model('RecipeHistory', RecipeHistorySchema);