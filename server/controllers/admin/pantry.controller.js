const PantryService = require('../../services/admin/pantry.service');
const ActivityLogService = require('../../services/admin/actlog.service');
const AdminService = require('../../services/admin/admin.service');

// Lấy danh sách thống kê (Màn hình chính quản lý Pantry)
const getPantryStats = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        // Có thể check quyền ở đây nếu cần

        const result = await PantryService.getPantryStatistics();
        
        if (!result || result.length === 0) {
            return res.status(200).json({success: false, message: "Chưa có dữ liệu pantry nào"});
        }
        
        return res.status(200).json({
            success: true, 
            message: "Lấy thống kê thành công", 
            data: result // Trả về mảng các user kèm số lượng item
        });

    } catch (err) {
        console.error("Lỗi khi lấy thống kê pantry", err);
        return res.status(500).json({success: false, message: "Lỗi server", error: err.message});
    }
};

// Xem chi tiết tủ đồ của 1 user cụ thể
const getPantryDetailsByUser = async (req, res) => {
    try {
        const userId = req.params.userId;
        const items = await PantryService.getPantryItemsByUserId(userId);
        
        return res.status(200).json({
            success: true, 
            message: "Lấy chi tiết thành công", 
            items: items
        });
    } catch (err) {
        console.error("Lỗi khi lấy chi tiết", err);
        return res.status(500).json({success: false, message: "Lỗi server", error: err.message});
    }
};

// Xoá thực phẩm (Ví dụ: Thực phẩm vi phạm quy định hoặc User yêu cầu)
const deletePantryItem = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({ success: false, message: "Bạn không có quyền." });
        }

        const itemId = req.params.id;
        const deletedItem = await PantryService.deletePantryItemById(itemId);

        if (!deletedItem) {
            return res.status(404).json({success: false, message: "Sản phẩm không tồn tại"});
        }

        // Ghi log hành động
        ActivityLogService.createLog({
            adminId: user._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "DELETE",
            targetCollection: 'PantryItem',
            targetId: deletedItem._id,
            targetName: deletedItem.name,
            description: `${user.role.roleName} ${user.username} đã xoá thực phẩm: ${deletedItem.name} (User ID: ${deletedItem.user})`,
            req: req
        });

        return res.status(200).json({success: true, message: "Xoá thành công", item: deletedItem});

    } catch (err) {
        console.error("Lỗi khi xoá pantry item", err);
        return res.status(500).json({success: false, message: "Lỗi server", error: err.message});
    }
};

module.exports = { getPantryStats, getPantryDetailsByUser, deletePantryItem };