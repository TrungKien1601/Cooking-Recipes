const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, index: true },
  description: { type: String, default: '' },
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false }, 
  // --- THÊM MỚI: Đánh dấu nguồn gốc ---
  source: { type: String, enum: ['User', 'AI'], default: 'User' }, 

  image: { type: String, required: false }, // AI có thể chưa có ảnh ngay, để false cho an toàn
  video: { type: String, default: '' },
  servings: { type: Number, default: 1 },
  cookTimeMinutes: { type: Number, default: 30 },
  difficulty: { type: String, enum: ['Dễ', 'Trung bình', 'Khó'], default: 'Trung bình' },
  status: { type: String, enum: ['Chờ duyệt', 'Đã duyệt', 'Từ chối'], default: 'Chờ duyệt' }, // AI tạo thì cho duyệt luôn
  ingredients: [{
    name: { type: String, required: true }, 
    quantity: { type: Number, required: true, default: 0 }, // Default 0 để AI không lỗi
    unit: { type: String, default: 'g' },
    masterIngredient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MasterIngredient'
    }
  }],
  search_ingredients: [{ type: String }], 
  steps: [{ description: String, image: String }], 
  chef_tips: { type: String, default: "" },

  nutritionAnalysis: {
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    sodium: { type: Number, default: 0 },
    sugars: { type: Number, default: 0 }
  },
  mealTimeTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  dietTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  regionTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  dishtypeTags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],

}, { timestamps: true });

// Index text cho cả Tên và Nguyên liệu tìm kiếm
recipeSchema.index({ name: 'text', search_ingredients: 'text' });

module.exports = mongoose.model('Recipe', recipeSchema);