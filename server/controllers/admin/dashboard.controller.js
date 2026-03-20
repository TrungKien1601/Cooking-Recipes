// controllers/admin/dashboard.controller.js
const DashboardService = require('../../services/admin/dashboard.service');

const getStatisticalCounts = async (req, res) => {
    try {
        // Gọi service để lấy số liệu
        const stats = await DashboardService.getSystemCounts();
        
        return res.status(200).json({
            success: true,
            message: "Lấy dữ liệu thống kê thành công.",
            data: stats 
        });
    } catch (err) {
        console.error("Lỗi Dashboard Controller:", err);
        return res.status(500).json({
            success: false,
            message: "Lỗi server khi lấy dữ liệu thống kê.",
            error: err.message
        });
    }
};

// [MỚI]
const getChartData = async (req, res) => {
    try {
        const chartData = await DashboardService.getGrowthChartData();
        return res.json({
            success: true,
            data: chartData // { users: [10, 5...], recipes: [2, 8...] }
        });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

module.exports = { 
    getStatisticalCounts,
    getChartData,
};