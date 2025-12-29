const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    recipient: { // Người nhận (Chủ công thức)
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true 
    },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: { // Loại thông báo
        type: String, 
        enum: ['Chờ duyệt', 'Đã duyệt', 'Từ chối','Cập nhật','Đã xóa'], 
        default: 'Đã duyệt' 
    },
    isRead: { type: Boolean, default: false }, // Đã đọc chưa
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notification', notificationSchema);