// server/utils/RecipePrompt.js

const getNutritionAnalysisPrompt = (ingredients, servings = 1) => {
  // servings mặc định là 1 nếu không truyền vào

  const ingredientsText = ingredients.map(i => 
    `- ${i.quantity} ${i.unit || ''} ${i.name}`
  ).join('\n');

  return `
    Bạn là chuyên gia dinh dưỡng chuyên nghiệp. Hãy phân tích danh sách nguyên liệu dưới đây:
    ${ingredientsText}

    Thông tin bổ sung: Món ăn này dành cho ${servings} người ăn.

    Yêu cầu tính toán:
    1. Đầu tiên, tính TỔNG dinh dưỡng của toàn bộ nguyên liệu trên dựa theo cơ sở dữ liệu chuẩn (như USDA). 
       *Lưu ý quan trọng*: Hãy dùng số liệu thực tế, đừng phóng đại. Ví dụ: Thịt ba rọi (Pork Belly) sống trung bình khoảng 518 calo/100g.
    2. Sau đó, CHIA TỔNG ĐÓ cho ${servings} để ra dinh dưỡng cho 1 KHẨU PHẦN (1 người ăn).
    
    Output bắt buộc (JSON thuần, chỉ trả về số liệu CHO 1 NGƯỜI ĂN):
    {
      "calories": number, // Calo cho 1 người
      "protein": number,  // Grams
      "carbs": number,    // Grams
      "fat": number,      // Grams
      "sodium": number,   // Milligrams
      "sugars": number    // Grams
    }

    Nếu không xác định được, trả về 0. Không giải thích thêm, chỉ trả về JSON.
  `;
};

module.exports = { getNutritionAnalysisPrompt };