const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, index: true },
  description: { type: String, default: '' },
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  image: { type: String, required: true },
  video: { type: String, default: '' },
  servings: { type: Number, default: 1 },
  cookTimeMinutes: { type: Number, default: 0 },
  difficulty: { type: String, enum: ['Dễ', 'Trung bình', 'Khó'], default: 'Trung bình' },
  status: { type: String, enum: ['Chờ duyệt', 'Đã duyệt', 'Từ chối'], default: 'Đã duyệt' },
  ingredients: [{
    name: { type: String, required: true }, 
    quantity: { type: Number, required: true },
    unit: { type: String, default: 'gram' },
    masterIngredient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MasterIngredient'
    }
  }],
  steps: [{ description: String, image: String }], 
  
  nutritionAnalysis: {
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    sodium: { type: Number, default: 0 },
    sugars: { type: Number, default: 0 }
  },

  // Tags
  mealTimeTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }], // Có muốn giữ hay không
  dietTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  regionTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  dishtypeTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],

}, { timestamps: true });

recipeSchema.index({ name: 'text' });

module.exports = mongoose.model('Recipe', recipeSchema);