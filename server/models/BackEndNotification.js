const mongoose = require('mongoose');

const backEndNotificationSchema = new mongoose.Schema({
  // Loại thông báo: Recipe mới hoặc User mới
  type: { 
      type: String, 
      enum: ['RECIPE_NEW', 'USER_NEW'], 
      required: true 
  },
  
  // Nội dung hiển thị
  message: { type: String, required: true },
  
  // Dùng refPath để liên kết động tới model 'Recipe' hoặc 'User'
  referenceId: { 
      type: mongoose.Schema.Types.ObjectId, 
      required: true, 
      refPath: 'referenceModel' 
  },
  referenceModel: { 
      type: String, 
      required: true, 
      enum: ['Recipe', 'User'] 
  },
  
  isRead: { type: Boolean, default: false }, // Trạng thái đã xem
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BackendNotification', backEndNotificationSchema);