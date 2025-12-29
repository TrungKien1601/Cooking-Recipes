const mongoose = require('mongoose');

const tagSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    required: true,
    // Enum định nghĩa chính xác các loại thẻ cho phép [cite: 46]
    enum: [
      'Vùng miền',
      'Cách chế biến',
      'Loại nguyên liệu',
      'Giờ ăn',
      'Chế độ ăn kiêng',
      'Tình trạng sức khoẻ',
      'Danh mục thực phẩm',
      'Dị ứng',
      'Thói quen',
      'Mục tiêu dinh dưỡng'
    ]
  }
}, { timestamps: true });

module.exports = mongoose.model('Tag', tagSchema);