// File: controllers/util.controller.js
const utilService = require('../../services/user/util.service'); // Import Service

const utilController = {
    searchImage: async (req, res) => {
        try {
            const { query } = req.query;

            // 1. Validate đầu vào
            if (!query) {
                return res.status(400).json({ 
                    success: false, 
                    message: "Vui lòng gửi từ khóa (query)" 
                });
            }

            // 2. Gọi Service để lấy dữ liệu
            const imageUrl = await utilService.findImageFromGoogle(query);

            // 3. Trả về kết quả cho Flutter
            return res.status(200).json({
                success: true,
                data: imageUrl
            });

        } catch (error) {
            console.error("Controller Error:", error);
            return res.status(500).json({ 
                success: false, 
                message: "Lỗi Server nội bộ" 
            });
        }
    }
};

module.exports = utilController;