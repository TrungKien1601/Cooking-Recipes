const ActivityLog = require('../../models/ActivityLog');

const ActivityLogService = {
    async selectAll() {
        const query = {};
        const result = await ActivityLog.find(query).sort({ updatedAt: -1}).exec();
        return result;
    },
    async filterLogs(value) {
        const keyword = { action: { $in: value } };
        const result = await ActivityLog.find(keyword).sort({ updatedAt: -1 }).exec();
        return result;
    },

    async createLog(data) {
        try {
            // Chúng ta không dùng 'await' ở đây để return, 
            // mà để nó chạy ngầm để không làm user phải chờ log ghi xong mới thấy phản hồi.
            // Tuy nhiên trong đồ án, để an toàn dữ liệu, bạn có thể dùng await.
            ActivityLog.create({
                adminId: data.adminId,
                adminName: data.adminName,
                adminRole: data.adminRole,
                adminEmail: data.adminEmail,
                action: data.action,
                targetCollection: data.targetCollection,
                targetId: data.targetId,
                targetName: data.targetName,
                description: data.description,
                ipAddress: data.req ? data.req.ip : null,
                userAgent: data.req ? data.req.headers['user-agent'] : null
            });

            console.log(`[LOG CREATE] ${data.action} - ${data.description}`);
        } catch (err) {
            console.log('Ghi log thất bại:', err)
        }
    }
};

module.exports = ActivityLogService;