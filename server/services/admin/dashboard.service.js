const Users = require('../../models/UserProfile');
const Recipes = require('../../models/Recipe');
const MasterIngredients = require('../../models/MasterIngredients');

const DashboardService = {
    /**
     * Lấy tổng số lượng các thực thể trong hệ thống
     * Dùng Promise.all để chạy song song giúp tối ưu hiệu năng
     */
    async getSystemCounts() {
        try {
            const [totalUsers, totalRecipes, totalIngredients] = await Promise.all([
                Users.countDocuments({}),             // Đếm tất cả user
                Recipes.countDocuments({}),           // Đếm tất cả công thức
                MasterIngredients.countDocuments({})  // Đếm tất cả nguyên liệu
            ]);

            return {
                users: totalUsers,
                recipes: totalRecipes,
                ingredients: totalIngredients
            };
        } catch (error) {
            throw error;
        }
    },

    // [MỚI] Lấy dữ liệu biểu đồ tăng trưởng theo tháng trong năm hiện tại
    async getGrowthChartData() {
        const currentYear = new Date().getFullYear();

        // Hàm helper để tạo pipeline Aggregation
        const createPipeline = (model) => [
            {
                $match: {
                    createdAt: {
                        $gte: new Date(`${currentYear}-01-01`),
                        $lte: new Date(`${currentYear}-12-31`)
                    }
                }
            },
            {
                $group: {
                    _id: { $month: "$createdAt" }, // Gom nhóm theo tháng (1-12)
                    count: { $sum: 1 }
                }
            },
            { $sort: { _id: 1 } } // Sắp xếp từ tháng 1 đến 12
        ];

        const [userStats, recipeStats] = await Promise.all([
            Users.aggregate(createPipeline(Users)),
            Recipes.aggregate(createPipeline(Recipes))
        ]);

        // Chuẩn hóa dữ liệu cho đủ 12 tháng (nếu tháng nào không có dữ liệu thì trả về 0)
        const formatData = (data) => {
            const result = Array(12).fill(0);
            data.forEach(item => {
                // item._id là tháng (1-12), mảng bắt đầu từ 0 nên trừ 1
                result[item._id - 1] = item.count;
            });
            return result;
        };

        return {
            users: formatData(userStats),
            recipes: formatData(recipeStats)
        };
    }
};

module.exports = DashboardService;