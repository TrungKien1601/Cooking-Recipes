const mongoose = require('mongoose');

const barcodeSchema = new mongoose.Schema({
  // 1. Mã vạch (Khóa chính)
  barcode: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true  
  },

  productName: { 
    type: String, 
    required: true 
  },
  
  brand: { 
    type: String, 
    default: "" 
  },
  
  description: {
    type: String,
    default: ""
  },

  // Lưu nguyên cục dinh dưỡng vào đây
  nutrients: {
    calories: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    protein: { type: Number, default: 0 }
  },

  image: {
    type: String, // Link ảnh sản phẩm (nếu có sau này)
    default: ""
  },
  masterIngredient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MasterIngredient',
    required: false 
  },
  scanCount: {
    type: Number,
    default: 1
  }

}, { timestamps: true });

module.exports = mongoose.model('Barcode', barcodeSchema);