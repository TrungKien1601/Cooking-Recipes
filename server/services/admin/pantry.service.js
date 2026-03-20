const PantryItem = require('../../models/PantryItem');

const PantryService = {
    // 1. Lấy thống kê: Danh sách User + Tổng số lượng sản phẩm họ có
    // (Dùng cho bảng danh sách bên ngoài)
    async getPantryStatistics() {
        const stats = await PantryItem.aggregate([
            // Gom nhóm theo User
            {
                $group: {
                    _id: "$user", 
                    totalProducts: { $sum: 1 }, // Đếm số lượng
                    lastUpdated: { $max: "$updatedAt" } // Lấy thời gian cập nhật gần nhất
                }
            },
            // Nối bảng User để lấy info (username, email)
            {
                $lookup: {
                    from: "users",
                    localField: "_id",
                    foreignField: "_id",
                    as: "userInfo"
                }
            },
            { $unwind: "$userInfo" }, // Làm phẳng mảng userInfo
            // Chỉ lấy các trường cần thiết
            {
                $project: {
                    _id: 1, // Đây là User ID
                    username: "$userInfo.username",
                    email: "$userInfo.email",
                    avatar: "$userInfo.avatar", // Nếu User có avatar
                    totalProducts: 1,
                    lastUpdated: 1
                }
            },
            // Sắp xếp người có nhiều đồ nhất lên đầu
            { $sort: { totalProducts: -1 } }
        ]);
        return stats;
    },

    // 2. Xem chi tiết: Lấy danh sách thực phẩm của 1 User cụ thể
    // (Dùng khi Admin bấm vào nút "Chi tiết" của user đó)
    async getPantryItemsByUserId(userId) {
        return await PantryItem.find({ user: userId })
            .populate('masterIngredient', 'name image') // Lấy tên/ảnh gốc từ kho nguyên liệu
            .sort({ expiryDate: 1 }) // Sắp xếp đồ sắp hết hạn lên đầu
            .exec();
    },

    // 3. Xoá 1 món (Dành cho Admin kiểm duyệt)
    async deletePantryItemById(_id) {
        return await PantryItem.findByIdAndDelete(_id).exec();
    }
}

module.exports = PantryService;