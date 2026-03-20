const Notification = require('../../models/BackEndNotification');

const NotificationService = {
    // 1. Lấy danh sách thông báo
    async getNotifications(limit = 10) {
        return await Notification.find()
            .sort({ createdAt: -1 }) // Mới nhất lên đầu
            .limit(limit)
            // Populate động: Nếu là Recipe lấy (name, image), nếu là User lấy (username, image)
            .populate('referenceId', 'name username image') 
            .exec();
    },

    // 2. Đếm số thông báo chưa đọc
    async countUnread() {
        return await Notification.countDocuments({ isRead: false });
    },

    // 3. Đánh dấu tất cả là đã đọc
    async markAllAsRead() {
        return await Notification.updateMany({ isRead: false }, { isRead: true });
    },

    // 4. Tạo thông báo mới
    async createNotification(data) {
        const noti = new Notification(data);
        return await noti.save();
    }
};

module.exports = NotificationService;