const NotificationService = require('../../services/admin/notification.service');

const getList = async (req, res) => {
    try {
        const list = await NotificationService.getNotifications();
        const unread = await NotificationService.countUnread();
        return res.json({ success: true, notifications: list, unreadCount: unread });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: err.message });
    }
};

const markRead = async (req, res) => {
    try {
        await NotificationService.markAllAsRead();
        return res.json({ success: true });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

module.exports = { getList, markRead };