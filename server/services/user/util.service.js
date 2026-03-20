// File: services/util.service.js
const axios = require('axios');

const utilService = {
    // Hàm tìm ảnh: Logic nghiệp vụ nằm ở đây
    findImageFromGoogle: async (query) => {
        try {
            const apiKey = process.env.GOOGLE_API_KEY;
            const cxId = process.env.GOOGLE_CX_ID;
            
            // Gọi Google Custom Search
            const url = `https://www.googleapis.com/customsearch/v1?q=${encodeURIComponent(query)}&cx=${cxId}&key=${apiKey}&searchType=image&num=1&imgSize=large&imgType=photo`;
            
            const response = await axios.get(url);

            if (response.data.items && response.data.items.length > 0) {
                return response.data.items[0].link; // Trả về link ảnh Google
            }
            
            // Nếu Google không tìm thấy, ném lỗi để xuống catch chạy fallback
            throw new Error("Google không tìm thấy ảnh");

        } catch (error) {
            console.log("Service Log - Google Search Error/Empty:", error.message);
            const fallbackUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(query)}%20cooked%20dish`;
            return fallbackUrl;
        }
    }
};

module.exports = utilService;