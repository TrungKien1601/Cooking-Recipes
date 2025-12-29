const mongoose = require('mongoose');

const ProductCacheSchema = new mongoose.Schema({
  barcode: { type: String, required: true, unique: true }, // Mã vạch làm khóa chính
  name: { type: String, required: true },
  category: String,
  image_url: String,
  unit: String,
  nutrients: {
    calories: Number,
    fat: Number,
    carbs: Number,
    protein: Number
  },
  source: String // Để biết là nguồn từ AI hay OFF
}, { timestamps: true });

module.exports = mongoose.model('ProductCache', ProductCacheSchema);